# North52 (N52) 语法速查手册

> 基于实际项目公式(Case_SavePerformAction_SetUtilizationBalanceByProduct 等)整理。
> 官方文档: https://support.north52.com (编辑器内 Functions 页签可查全部函数签名)
> 核心心法: **N52里一切都是"表达式返回值",没有语句、没有代码块。**

---

## 1. 字段引用语法

| 写法 | 含义 |
|---|---|
| `[incident.casetypecode]` | 取当前记录(incident)的字段值 |
| `[incident.aia_ebplanid]` | lookup字段 → 取到的是关联记录的ID |
| `[incident.aia_medicalplanid.aia_annualbalance]` | **点路径穿透**: 沿lookup到关联实体取字段(可多层) |
| `[incident.aia_planid.aia_balance.0]` | 尾缀 `.0` = null保护, 空值按 **0** 参与运算 |
| `[incident.aia_profileid.aia_relationship.?]` | 尾缀 `.?` = null保护, 空值返回 **'?'** |

> 穿透多层示例(本项目实际用例):
> `[incident.aia_ebcustomerproductid.aia_ebcustomerproductgroupid.aia_annualbalance.?]`
> Case → EB客户产品 → EB客户产品组 → 年度余额

## 2. 花括号语法(三种,别混淆)

| 写法 | 用在哪 | 含义 |
|---|---|---|
| `{Claim}` `{No}` `{EB}` | 决策表条件格 | 匹配**选项集/布尔字段的标签文本** |
| `{Spouse}{Member}` | 决策表条件格 | 同格多值 = **OR**(是其一即可) |
| `{HasProductGroup}` | 任意表达式位置 | **Snippet引用**: 调用Global Calculations里定义的片段(求值时会执行其内部全部逻辑,含副作用!) |
| `{{{ContainsData}}}` | 决策表条件格 | 该列来源字段**有值**即通过 |
| `{{{DoesNotContainData}}}` | 决策表条件格 | 该列来源字段**为空**才通过 |

## 3. 字面量与运算符

| 写法 | 含义 |
|---|---|
| `'100000001'` | 单引号 = **字符串** |
| `100000000` | 无引号数字 = 数值(选项集比较时为选项Value) |
| `TRUE` / `true` `false` | 布尔 |
| `=` | **比较**(不是赋值!N52没有==) |
| `<>` | 不等于 |
| `>` `<` `>=` `<=` | 数值比较 |
| `and` `or` | 逻辑运算(也可用函数 `And()` `Or()` `Not()`) |
| `+` | 加法/字符串拼接 |
| `'?'` | **特殊标记**: 动作列返回'?' = **跳过更新该字段**(do nothing) |

## 4. 决策表结构

```
        A列(黄=条件)    B列(黄=条件)    K列(绿=动作)
第1行   Condition       Condition       Action-Targetentity / Action-Command
第2行   条件显示名       条件显示名       动作显示名
第3行   取值来源/基准     取值来源/基准     目标字段逻辑名(Targetentity时)
第4行+  规则行...
```

**读表规则:**
- 第3行是**字段引用** → 规则格写匹配值(如`{Claim}`)
- 第3行是 **TRUE** → 规则格写完整布尔表达式,算出TRUE才通过
- 第3行是 **'Yes'等字面量** → 规则格表达式的返回值须等于它
- **空白格 = 不检查(通配)**
- 同一行所有非空格之间 = **AND**;行与行之间 = 逐行竞争
- 某行条件格填了值、下方行同列空白 → 空白≠继承(仅当上方行**其余列全空**时才是"公共条件行",如单独一行`{Claim}`)

**动作列两种:**
| 列头 | 行为 |
|---|---|
| `Action-Targetentity` | 格子表达式的返回值 → **写入第3行指定的字段** |
| `Action-Command` | 格子表达式**被执行**(通常是Snippet/操作),不落库到特定字段 |

**Hit Policy(右键 → Hit Policy):**
- `Exit this Decision Table on First Match` **默认勾选** = 命中即停(else-if链)
- 取消勾选 = 每行都评估,多行命中都执行(同字段则last-write-wins)
- `Exit All Decision Tables on First Match` = 多sheet时全部退出

**底部页签:** DecisionTable(主表) / Global Calculations(Snippet定义) / Global Actions / Global FetchXml(共享查询)。F4切换Advanced Mode显示隐藏页签。

## 5. 核心函数速查

### 5.1 流程控制

| 函数 | 签名 | 说明 |
|---|---|---|
| `if` | `if(条件, 真值, 假值)` | 三元表达式,**两个分支都必须有值**。嵌套实现else-if |
| `iftrue` | `iftrue(条件, 动作)` | 只有真分支,假时无事发生。SmartFlow里当普通if语句用 |
| `Case` | `Case(值, 匹配1,结果1, 匹配2,结果2, ..., 默认)` | 多路分支(switch) |
| `SmartFlow` | `SmartFlow(步骤1, 步骤2, ..., 步骤N)` | **顺序执行**所有参数,返回**最后一个参数**的值。N52的"语句块" |

**心智映射:**
```
iftrue(A, X)        ≈  if (A) { X }
if(A, X, Y)         ≈  A ? X : Y
SmartFlow(X,Y,Z)    ≈  { X; Y; return Z; }
```

### 5.2 变量(执行期内存,不落库)

| 函数 | 说明 |
|---|---|
| `SetVar('名', 值)` | 存变量。名字是**作者自定义字符串**,无声明无类型,元数据里查不到 |
| `GetVar('名')` | 取变量。**仅当确定已无条件赋值过**时用单参数 |
| `GetVar('名', 默认值)` | 取变量,不存在返回默认值。**条件分支里才赋值的变量必须用这个** |

- 作用域: 同一次公式执行内跨Snippet可见;执行结束销毁
- 常见模式: `GetVar('FinalBalanceValue', '?')` — 没算出结果就跳过字段更新
- 常见模式: 布尔标志只写 `SetVar('Flag', true)`,false靠 `GetVar('Flag', false)` 默认值兜底

### 5.3 数据查询

| 函数 | 说明 |
|---|---|
| `FindValue('实体','键字段',键值,'取值字段')` | 按键查记录取单字段。可加第5参数作查不到时的默认值 |
| `FindValueQuickId(...)` / FetchXml相关 | 复杂查询走 Global FetchXml 页签定义,公式中引用 |
| `ContainsData(x)` | x有值 → true |
| `DoesNotContainData(x)` | x为空 → true |
| `ToString(x)` | 转字符串(多选选项集→逗号分隔列表,常配MatchList用) |

### 5.4 列表/多选选项集

多选Picklist存储形式 = 逗号分隔的选项值字符串,如 `"100000001,100000002"`。

| 函数 | 说明 |
|---|---|
| `MatchListFindIntersectExists(列表1, 列表2)` | 两列表**有交集** → true。判断"多选字段**包含**某选项"的标准姿势 |
| `MatchListFindIntersect(列表1, 列表2)` | 返回交集本身 |
| `MatchListValueExists(列表, 值)` | 单值是否在列表中 |

**标准用法(判断计划限额类型包含"年度"):**
```
MatchListFindIntersectExists(
    ToString(FindValue('aia_ebplan','aia_ebplanid',
                       [incident.aia_ebplanid],'aia_benefitlimittype')),
    '100000001')
```

### 5.5 其他常用

| 函数 | 说明 |
|---|---|
| `Min(a,b)` / `Max(a,b)` | 最值(决策表里也常见拆成 >/</= 三行的表格化写法) |
| `DateDiff(from, to, 'interval')` | 日期差 |
| `UtcDate()` / `UtcNow()` | 当前时间 |
| `CreateRecord / UpdateRecord / UpdateCreateRecordById` | 增改记录(多在Global Actions里) |
| `CurrentRecord('id')` | 当前记录GUID |

## 6. Formula Type(公式类型)与触发

| 类型 | 触发方式 |
|---|---|
| **Save - Perform Action** | 记录保存(Create/Update)时**自动**在插件管道执行,可写字段/建记录 |
| Save - To Current Record | 保存时计算并回写当前记录 |
| **Process Genie** | **被动**:按钮/JS/工作流/其他公式显式调用;有Display Format定义返回值 |
| ClientSide - Calculation | 表单端实时计算 |
| Schedule | 定时批量执行 |

**Register页关键项(Save类):**
- Mode: Server Side = 任何来源(UI/API/导入/Flow)都触发
- Event: Create / Update / Create & Update
- **Source Property = 过滤字段**(多选): Update时仅当勾选字段变更才执行;All Properties = 任何字段
- Pipeline Stage: Pre-Operation(写库前,同事务,改Target不引发二次Update) / Post-Operation / Async
- Execute As: CallingUser(注意用户权限) / SYSTEM
- Execution Order: **N52内部**多条公式间的顺序
- Trace Level: **Off时Formula Trace不记录**,调试前先开

**架构须知:** N52用共享插件step(`North52...AnyEntity.SingleFormula`,Filtering Attributes=All)做统一入口,**真正的字段过滤在N52引擎内按每条公式的Source Property执行**。Plugin Registration Tool里看不到单条公式的过滤配置。

## 7. 调试与排查手段

| 手段 | 用途 |
|---|---|
| **Formula Trace页签** | 开启后保存记录触发,trace逐步显示: 命中哪行、每个条件实际值、每个SetVar/GetVar的运行时值。**查变量实际值的唯一途径** |
| **Source页签** | 查看决策表编译后的完整公式代码,Ctrl+F搜变量/函数 |
| **Functions页签** | 全部内置函数签名与可选参数 |
| **闪电按钮(Test)** | 建临时Process Genie写一行表达式直接执行,函数语义沙盒 |
| 编辑器放大镜 | 跨sheet搜索变量名/Snippet名 |

## 8. 常用控制台脚本(F12,已登录的D365页面)

**查picklist选项(已知实体+字段):**
```javascript
fetch("/api/data/v9.2/EntityDefinitions(LogicalName='实体名')/Attributes(LogicalName='字段名')/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?$expand=OptionSet($select=Options)")
  .then(r=>r.json()).then(d=>d.OptionSet.Options.forEach(o=>
    console.log(o.Value,'=>',o.Label.UserLocalizedLabel.Label)));
// 多选换成 MultiSelectPicklistAttributeMetadata
```

**只知字段名反查实体+选项:** 先查 `EntityDefinitions?$expand=Attributes($filter=LogicalName eq '字段名')` 找实体,再跑上面。

**抓N52编辑器Source Property选中项:**
```javascript
copy([...document.querySelectorAll('#metadataproperty option:checked')]
  .map(o=>o.value+'\t'+o.text).join('\n'))
// 注意iframe: Console顶部context下拉切到编辑器frame
```

**查N52公式记录本体(URL里的id):**
```javascript
fetch("/api/data/v9.2/north52_formulas(公式GUID)").then(r=>r.json())
  .then(d=>Object.entries(d).filter(([k,v])=>typeof v==='string'&&v)
  .forEach(([k,v])=>console.log(k,'=>',v.substring(0,300))));
```

## 9. 项目惯用模式备忘(读本环境公式时的经验)

1. **'?' = 跳过更新**,不是写问号。`if(条件, 值, '?')` / `GetVar(x,'?')` 到处都是
2. **条件Snippet常带副作用**("条件顺便干活"): `{HasProductGroup}` 求值时完成余额计算存入FinalBalanceValue,再返回布尔。**读任何`{Snippet}`必须去Global Calculations看实现,名字会骗人**
3. **门闩模式**: `{OriginCanProcess}` 用"数据就绪布尔字段"拦截过早计算;该字段同时列入Source Property,翻true时自动触发重算
4. **决策表行序=优先级**(命中即停时): 具体规则(产品组/特殊人群)在上,通用规则在中,兜底(DoesNotContainData或全空行)在下
5. **多选包含≠等于**: MatchListFindIntersectExists是"包含";计划勾多个限额类型时,行序决定哪个限额优先
6. **变量名可能有拼写错误**(BenefitLimeitTypeList/HasLimitTypeAnnaul),搜索时按错的拼法搜
7. **null保护四件套**: `.0` `.?` `GetVar(x,默认)` `FindValue(...,默认)` — 生产公式必备
