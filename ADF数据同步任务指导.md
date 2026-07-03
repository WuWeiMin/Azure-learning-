# ADF 数据同步任务完整指导

> 任务:同表库内模拟 A→B 同步。比对源表与 `aia_batchcycleconfig`,有差异则更新,并把每条变更推送到 Service Bus。
>
> Pipeline 结构:`Stored Proc(MERGE比对更新) → Lookup(读变更) → ForEach [ Web(发消息) → Stored Proc(标记已发) ]`

---

## 0. 字段映射(本方案的基础)

| 源表(模拟 onedata) | 目标表 aia_batchcycleconfig | 角色 |
|---|---|---|
| application_name | aia_name | 关联键(JOIN 条件) |
| previous_cycle_date | aia_lastcycledate | 比对 + 更新 |
| current_cycle_date | aia_currentcycledate | 比对 + 更新 |
| next_cycle_date | aia_nextcycledate | 比对 + 更新 |
| before_previous_cycle_date | (不同步) | — |
| — | aia_excutecycledate | 不映射,保持原值 |
| — | aia_id | 主键,INSERT 时生成 |

**开始前需要你替换的占位符(全文一致):**

| 占位符 | 含义 | 示例 |
|---|---|---|
| `{{源表名}}` | 模拟 A 库的那张表 | dbo.onedata_batchcycle |
| `{{命名空间}}` | Service Bus 命名空间 | mysb001 |
| `{{队列名}}` | Service Bus 队列 | sync-changes |

---

## 第 1 步:确认表结构(SSMS)

先跑这个查询,确认两张表的实际列类型和 aia_id 的类型:

```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('aia_batchcycleconfig', '{{源表名去掉dbo.}}')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

- 如果 `aia_id` 是 **uniqueidentifier** → 后面脚本用 `NEWID()`,不用改。
- 如果是 **int + IDENTITY** → 把第 3 步 INSERT 里的 `aia_id` 和 `NEWID()` 两处删掉即可。
- 日期列如果是 `datetime` 而不是 `datetime2`,不影响,脚本通用。

---

## 第 2 步:创建变更日志表(SSMS)

```sql
CREATE TABLE dbo.SyncChangeLog (
    LogId               INT IDENTITY(1,1) PRIMARY KEY,
    ChangeType          NVARCHAR(10)  NOT NULL,          -- INSERT / UPDATE
    AiaName             NVARCHAR(200) NOT NULL,          -- 变更的记录(业务键)
    NewLastCycleDate    DATETIME2     NULL,
    NewCurrentCycleDate DATETIME2     NULL,
    NewNextCycleDate    DATETIME2     NULL,
    ChangedOn           DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    IsSent              BIT           NOT NULL DEFAULT 0 -- 消息是否已发送
);
```

`IsSent` 是幂等的关键:发送成功才置 1,pipeline 重跑不会重发已发过的消息。

---

## 第 3 步:创建 MERGE 存储过程(SSMS)

```sql
CREATE OR ALTER PROCEDURE dbo.usp_Sync_BatchCycleConfig
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.aia_batchcycleconfig AS t
    USING {{源表名}} AS s
        ON t.aia_name = s.application_name

    -- 只有字段真的不一样才 UPDATE(ISNULL 处理空值比对)
    WHEN MATCHED AND (
           ISNULL(t.aia_lastcycledate,    '1900-01-01') <> ISNULL(s.previous_cycle_date, '1900-01-01')
        OR ISNULL(t.aia_currentcycledate, '1900-01-01') <> ISNULL(s.current_cycle_date,  '1900-01-01')
        OR ISNULL(t.aia_nextcycledate,    '1900-01-01') <> ISNULL(s.next_cycle_date,     '1900-01-01')
    ) THEN
        UPDATE SET
            t.aia_lastcycledate    = s.previous_cycle_date,
            t.aia_currentcycledate = s.current_cycle_date,
            t.aia_nextcycledate    = s.next_cycle_date

    -- 源有目标没有的记录 → 新增(aia_id 若为 IDENTITY,删掉下面的 aia_id 和 NEWID())
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (aia_id, aia_name, aia_lastcycledate, aia_currentcycledate, aia_nextcycledate)
        VALUES (NEWID(), s.application_name, s.previous_cycle_date, s.current_cycle_date, s.next_cycle_date)

    -- 捕获本次实际发生的变更,写入日志表
    OUTPUT
        $action,
        inserted.aia_name,
        inserted.aia_lastcycledate,
        inserted.aia_currentcycledate,
        inserted.aia_nextcycledate
    INTO dbo.SyncChangeLog
        (ChangeType, AiaName, NewLastCycleDate, NewCurrentCycleDate, NewNextCycleDate);
END
GO
```

再建一个"标记已发送"的存储过程:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_MarkChangeSent
    @LogId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.SyncChangeLog SET IsSent = 1 WHERE LogId = @LogId;
END
GO
```

---

## 第 4 步:纯 SQL 验证逻辑(SSMS,搭 ADF 之前必做)

在源表里造三类数据:

```sql
-- ① 与目标完全一致的记录 → 预期:MERGE 跳过,不进日志
-- ② 某个 cycle date 不同的记录 → 预期:UPDATE + 进日志
-- ③ 目标表里不存在的 application_name → 预期:INSERT + 进日志
-- (根据你的实际数据 INSERT/UPDATE 源表来构造这三种情况)

EXEC dbo.usp_Sync_BatchCycleConfig;

-- 检查结果
SELECT * FROM dbo.SyncChangeLog ORDER BY LogId DESC;
SELECT * FROM dbo.aia_batchcycleconfig;

-- 关键验证:立刻再跑一次,日志表不应新增任何行(说明"无差异不更新"生效)
EXEC dbo.usp_Sync_BatchCycleConfig;
SELECT COUNT(*) AS 新增行数 FROM dbo.SyncChangeLog WHERE IsSent = 0;
```

三类结果都符合预期、且第二次执行日志零新增,SQL 层就完工了。

---

## 第 5 步:准备 Service Bus(需要环境提供方配合)

你没有 Portal 权限,需要向环境提供方索取三样东西:

1. Service Bus **命名空间**(形如 `xxx.servicebus.windows.net`)
2. **队列名**
3. 一个具有 **Send 权限**的 Shared Access Policy 的 **名称 + Key**(或完整连接字符串)

拿到后,在你本机 PowerShell 里生成一个长效 SAS Token(下例有效期 1 年):

```powershell
Add-Type -AssemblyName System.Web
$URI     = "{{命名空间}}.servicebus.windows.net/{{队列名}}"
$KeyName = "策略名称"          # 例如 RootManageSharedAccessKey
$Key     = "策略的Key"
$Expires = ([DateTimeOffset]::Now.ToUnixTimeSeconds()) + 31536000
$SigStr  = [System.Web.HttpUtility]::UrlEncode($URI) + "`n" + $Expires
$HMAC    = New-Object System.Security.Cryptography.HMACSHA256
$HMAC.Key = [Text.Encoding]::UTF8.GetBytes($Key)
$Sig     = [Convert]::ToBase64String($HMAC.ComputeHash([Text.Encoding]::UTF8.GetBytes($SigStr)))
"SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($URI) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($Sig) + "&se=" + $Expires + "&skn=" + $KeyName
```

输出的整串 `SharedAccessSignature sr=...` 就是后面 Web Activity 要用的 Authorization 头,先存好。

> Service Bus 暂时没到位?没关系,第 6~8 步可以先做,把 Web Activity 那一步留空或先用 Debug 跳过,消息部分最后补。

---

## 第 6 步:创建 Dataset(ADF Studio)

只需要一个通用 Dataset 供 Lookup 使用:

1. **Author**(铅笔图标)→ Datasets → **+ → New dataset**
2. 选 **Azure SQL Database** → Continue
3. Name:`ds_sqldb_b`;Linked service:选你已建好的那个;**Table name 留空(选 None)**;Import schema 选 **None**
4. 点 OK,发布前先留着

> Table 留空是因为 Lookup 会直接写查询,不依赖固定表;这也避开了你之前 schema 导入报错的问题。

---

## 第 7 步:搭建 Pipeline(ADF Studio)

**Author → Pipelines → + → Pipeline**,命名 `pl_sync_batchcycle`。依次拖入并连接(全部用绿色"成功"箭头连接):

### 7.1 Stored Procedure Activity:执行同步

- Activities 面板搜 "Stored procedure" 拖入,命名 `SP_MergeSync`
- Settings → Linked service:选你的 Linked Service
- Stored procedure name:`dbo.usp_Sync_BatchCycleConfig`

### 7.2 Lookup Activity:读取未发送变更

- 拖入 Lookup,命名 `LK_GetChanges`,连接在 SP_MergeSync 之后
- Settings → Source dataset:`ds_sqldb_b`
- Use query:选 **Query**,填:

```sql
SELECT LogId, ChangeType, AiaName,
       CONVERT(VARCHAR(33), NewLastCycleDate,    126) AS LastCycleDate,
       CONVERT(VARCHAR(33), NewCurrentCycleDate, 126) AS CurrentCycleDate,
       CONVERT(VARCHAR(33), NewNextCycleDate,    126) AS NextCycleDate,
       CONVERT(VARCHAR(33), ChangedOn,           126) AS ChangedOn
FROM dbo.SyncChangeLog
WHERE IsSent = 0
ORDER BY LogId;
```

- **取消勾选 "First row only"**(要拿全部行)

> 注意:Lookup 上限 5000 行。练手数据量不会触及;生产上应改用 Copy Activity 直接批量落地到消息通道。

### 7.3 ForEach Activity:遍历变更

- 拖入 ForEach,命名 `FE_Changes`,连接在 LK_GetChanges 之后
- Settings → Items 填表达式:

```
@activity('LK_GetChanges').output.value
```

- Sequential 勾上(练手时顺序执行,日志好读;之后可去掉并发跑)

### 7.4 ForEach 内部:Web Activity 发消息

双击 ForEach 进入内部画布,拖入 **Web** Activity,命名 `WEB_SendToSB`:

- URL:

```
https://{{命名空间}}.servicebus.windows.net/{{队列名}}/messages
```

- Method:**POST**
- Headers 添加两条:
  - `Authorization` = 第 5 步生成的完整 SAS Token(以 `SharedAccessSignature` 开头的整串)
  - `Content-Type` = `application/json`
- Body:

```
@string(item())
```

这会把当前变更行整体序列化为 JSON 发出,消息体形如:
`{"LogId":12,"ChangeType":"UPDATE","AiaName":"AppA","CurrentCycleDate":"2026-07-01T00:00:00", ...}`

### 7.5 ForEach 内部:标记已发送

仍在 ForEach 内部,拖入 **Stored procedure** Activity,命名 `SP_MarkSent`,用绿色箭头连接在 WEB_SendToSB 之后:

- Stored procedure name:`dbo.usp_MarkChangeSent`
- Parameters → Import/新增参数:`LogId`,类型 Int32,Value:

```
@item().LogId
```

只有消息发送成功才会走到这一步,所以发送失败的记录 IsSent 仍为 0,下次运行自动重试——这就是幂等设计。

---

## 第 8 步:调试与发布

1. 画布顶部点 **Debug**,观察底部 Output 面板每个 Activity 的状态
2. 全绿后,去 SSMS 验证:`SELECT * FROM SyncChangeLog` 应全部 `IsSent = 1`
3. 如果有 Service Bus 的查看权限,可用 Service Bus Explorer 看队列里的消息
4. 一切正常 → 点顶部 **Publish all** 发布

**再次修改源表数据 → 再 Debug 一次**,验证增量变更被正确捕获和发送。

---

## 第 9 步:添加定时触发器

1. Pipeline 画布顶部 **Add trigger → New/Edit → + New**
2. Type:**Schedule**;Recurrence:如每 15 分钟或每天固定时间
3. OK → **Publish all**(Trigger 必须发布后才生效)

---

## 第 10 步:将来接入真实 A 库时怎么改

1. 新建一个指向 A 库的 Linked Service + 源 Dataset
2. 在 pipeline 最前面加一个 **Copy Activity**:A 库源表 → B 库 staging 表(结构同现在的模拟源表)
3. 存储过程里的 `{{源表名}}` 改为 staging 表名
4. 其余(MERGE 逻辑、日志、消息、触发器)全部不动

---

## 常见错误速查

| 现象 | 原因 | 处理 |
|---|---|---|
| Web Activity 401 | SAS Token 过期/拼错/策略无 Send 权限 | 重新生成 Token,确认整串完整粘贴 |
| Web Activity 超时 | 命名空间或队列名拼错 | 核对 URL,注意别带多余空格 |
| MERGE 报 aia_id 不能为 NULL | aia_id 是 IDENTITY 却手动插值,或相反 | 按第 1 步确认的类型调整 INSERT |
| MERGE 报重复键 | 源表 application_name 有重复值 | MERGE 要求源侧关联键唯一,先去重 |
| Lookup 报 schema/interactive authoring 错 | Dataset 或 IR 配置 | 确认 Dataset 的 Table 为 None、Linked Service 用 AutoResolve IR |
| 日志表越来越大 | 正常积累 | 定期归档:`DELETE FROM SyncChangeLog WHERE IsSent=1 AND ChangedOn < DATEADD(DAY,-30,SYSUTCDATETIME())` |

---

*文档生成日期:2026-07-03。占位符替换后即可按序执行。*
