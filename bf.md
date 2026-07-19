# 业务词汇与整体框架梳理
# Business Glossary & Overall Business Framework

> 说明：所有专业词汇均以 **English + 中文** 双语呈现；标注 ⚠️ 的词汇为文档中未给出全称、需业务方确认的缩写。

---

## Part 1. 业务词汇梳理 / Business Glossary

### 1.1 业务线与保单相关 / Line of Business & Policy

| 术语 English | 中文 | 说明 |
|---|---|---|
| EB (Employee Benefit) | 员工福利（团体险） | 企业为员工投保的团体医疗保险业务线，层级为 Company → EB Policy → EB Plan → Policy Profile → Member |
| IB (Individual Benefit) | 个人福利（个人险） | 个人医疗保险业务线，层级为 IB Policy → IB Policy Plan / Top Up Plan / Health Reward → Contact |
| Policy | 保单 | 保险合同主体记录 |
| Policy Profile | 保单档案 | 保单在 CRM 中的核心档案实体，EB/IB 两线共用概念 |
| Member | 成员（团体险被保人） | EB 线下受保的员工/家属 |
| Contact | 联系人（个人险被保人） | IB 线下的个人客户 |
| EB Plan / IB Policy Plan | 计划 | 保单下的保障计划 |
| IB Top Up Plan | 附加/加购计划 | IB 保单的附加计划 |
| IB Health Reward | 健康奖励 | IB 的健康奖励型附加权益 |
| Product Group / Product Type | 产品组 / 产品类型 | EB 产品主数据分类 |
| Benefit Group / Benefit Code | 利益组 / 利益代码 | 保障责任的分组与代码（EB Customer Benefit 挂接） |
| IB Plan Code / IB Plan Benefit Code / IB Benefit Code | IB 计划代码 / 计划利益代码 / 利益代码 | IB 侧产品与责任主数据 |
| EB Customer Product Group / Product / Benefit Group / Benefit | EB 客户产品组 / 产品 / 利益组 / 利益 | 客户（保单）层面对产品与责任的实例化记录 |
| Policy Status: IF / PE / PR | 保单状态：IF / PE / PR ⚠️ | 患者搜索校验用的有效状态码（推测 IF = In Force 生效；PE / PR 待确认） |
| Policy Status: LAPSED | 保单失效 | CRM 患者搜索中失效保单以红色行显示 |
| Underwriting Code 4 / 7 | 核保代码 4 / 7 ⚠️ | 流程用 “<> 4/7” 判断，具体含义需确认 |
| Waiting Period | 等待期 | 保单生效后的免责等待期；等待期内仅承保意外（trauma caused by accident） |
| Premium Paid Date | 保费缴纳日期 | IB 请求校验点：> 30 天则检查现金价值 |
| Cash Value | 现金价值 | IB 保单现金价值，用于抵扣欠缴保费 |
| Co-share / Deductible | 共担比例 / 免赔额 | 患者自付部分，提交请求前需患者确认同意 |
| Utilization Balance | 使用额度余额 | 保障额度剩余，不足则无法提交请求 |
| Privilege Card | 特权卡 | 持卡人可跳过额度检查直接进入请求表单 |
| Product Type: GHS / GMT / GSP | 产品类型 GHS / GMT / GSP ⚠️ | EB 患者搜索中的产品类型判断分支，全称需确认 |

### 1.2 担保函与请求类型 / Guarantee Letter & Request Types

| 术语 English | 中文 | 说明 |
|---|---|---|
| GL (Guarantee Letter) | 担保函 | 保险公司向医院出具的付款担保函，整个系统的核心对象 |
| IGL (Initial Guarantee Letter) | 初始担保函 | 入院时签发的首张担保函 |
| FGL (Final Guarantee Letter) | 最终担保函 | 出院/账单结算时的最终担保函 |
| Open GL | 开放式担保函 | 仅 EB 适用；符合条件的 Policy Profile + 指定医院可绕过额度检查（适用 Admission、New Visit、Medical Check-Up/Health Screening） |
| Offline GL | 线下担保函 | 核心系统查不到成员信息时，通过邮件人工创建成员后处理的 GL 流程 |
| LOG# (Log Number) | 日志号 | 同一次住院各请求共享的编号；GL 批准后激活 Log |
| Admission Request | 入院申请 | 住院流程的发起请求，后续请求都须挂接（tag）它 |
| Additional GL Request | 追加担保函申请 | 住院中新增诊断/操作时提出，可部分批准，被拒条目可申诉 |
| Top-Up Request | 额度追加申请 | 初始批准额度不足（住院延长/追加用药等）时申请 |
| Discharge Request | 出院申请 | 出院时提出，可补充医生/诊断，需审核员批准 |
| Amended Bill Request | 修正账单申请 | 按审核员要求修改账单后重新提交 |
| Final Bill Submission | 终版账单提交 | 金额必须等于 AIA 批准金额；出院批准后 7 天未提交系统自动创建 |
| Follow-Up GL Request | 复诊担保函申请 | 出院后复诊（post-hospitalization）担保申请，须关联原 Admission |
| Follow-Up Bill Submission | 复诊账单提交 | 针对 Follow-Up GL 的账单提交 |
| Outpatient (OP) Request | 门诊请求 | 类型：New Visit 新就诊 / Follow-up Visit 复诊 / Procedural 操作 / Medication 用药 / Medical Check-up & Health Screening 体检筛查 |
| OP Bill / OP Amended Bill / OP Final Bill Submission | 门诊账单 / 门诊修正账单 / 门诊终版账单提交 | 门诊侧的三种账单请求 |
| Procedural Request | 操作/手术申请 | 仅 EB 适用；含 Appeal Case、Imaging Case、First Procedural Category 等判断分支 |
| Maternity Request | 产科申请 | 仅 EB 适用；按 Reason of Visit 分住院/分娩与门诊 |
| Appeal Request | 申诉申请 | 对被拒 GL 的申诉；区分 Main Request / Sub-case，仅允许一次（First Appeal 判断） |
| Claim Cancellation | 理赔取消 | 取消主请求或子请求；EB 走 G400 取消（Status = CR），需要时人工在 MCS 取消并 SMS 通知客户 |
| Case Reopen | 案件重开 | Closed/Resolved 案件重开修正；从最后批准案件触发，原记录置 Cancelled-Reopen 并复制为新案件；旧 IGL/FGL/赔付需在后端手工取消 |
| E-Referral | 电子转诊 | 与 e-Referral Medi-connect 系统集成的转诊请求提交/查询流程 |
| Pre-Employment Screening | 入职前体检 | Portal 提交 → CRM 人工评估 → 批准生成 GL 模板 |
| Report Request | 报表申请 | Provider 通过 Portal 申请对账单（Statement of Account），CRM 按理赔付款记录生成 |

### 1.3 审核与作业管理 / Assessment & Case Management

| 术语 English | 中文 | 说明 |
|---|---|---|
| Case | 案件 | 每个请求在 CRM 中创建为一个 Case；同 GL+LOG# 的案件以 related case 关联 |
| Assessor | 审核员 | CRM 中处理理赔/GL 审核的核心角色 |
| AUC Assessor | AUC 审核员 | 专门处理 AUC 澄清事项的审核员 |
| Supervisor | 主管 | 可查看全部案件、分派案件、维护审核员排班、发起 Coaching |
| Manual Assessment | 人工审核 | STP 未自动通过时转人工评估 |
| STP (Straight-Through Processing) | 直通式处理 | 业务规则引擎自动判定批准/拒绝/转人工 |
| QMS (Queue Assignment) | 队列分配（排队管理系统） | 为请求生成队列号（前缀逻辑）、按优先级和排班把案件派给审核员；找不到可用审核员时等待 30 秒重试；多个可用时派给等待最久者 |
| Queue Assessor Setup | 队列审核员设置 | 主管创建审核员、手工维护或 Excel 上传排班 |
| Deferment | 延期（补充材料）流程 | 需要更多信息时向医院（Portal 交互）或第三方（如 Doctor、MOH，人工跟进）发起；含 Deferment Line 明细，状态 Sent → Received → Responded → Completed / Cancelled |
| AUC (Amount Under Clarification) | 待澄清金额 | 出院/账单流程中审核员录入的待澄清金额；仅适用于住院出院、门诊账单、修正账单、Follow-Up 账单；AUC Query 可发给 Provider 或第三方 |
| AUC Query / AUC Query Line | AUC 质询 / 质询明细行 | AUC 流程中的往来沟通记录 |
| Appeal (line-level) | 条目级申诉 | Additional GL 中被拒条目（Lines with Declined）可申诉 |
| Deferment? / Approve? / Resolve? | 判断节点：是否延期 / 是否批准 / 是否解决 | 流程图中常见决策菱形 |
| Decline Reason / Decline Letter | 拒绝原因 / 拒绝函 | 拒绝后更新原因并生成拒绝函 |
| Supervisor Review and Action Item | 主管审阅与行动项 | USD 中主管专属区，可自领（Self）或指派（Assign）案件 |
| Coaching | 辅导记录 | 主管创建 → 指派审核员 → 双方更新完成；用于案件处理沟通与辅导 |
| Call Log | 通话记录 | 联络中心坐席记录来电；坐席对案件只读，仅可创建/更新 Call Log，不能访问 AUC Query |
| Contact Centre Agent | 联络中心坐席 | 使用 CRM 界面（非 USD）的客服角色 |
| Library / Knowledge Base | 知识库 | 基于 CRM 标准 Knowledge Base，文章仅存于 CRM 内 |
| Announcement | 公告 | CRM 维护，未过期且在发布期内的公告推送到 Provider Portal；用户阅读产生 Tracking record |
| Emergency Case | 急诊案件 | 急诊分支可跳过部分网络/额度限制判断 |
| Late Submission / Late Indicator | 逾期提交 / 逾期标记 | 门诊账单逾期提交时更新标记 |
| Within 7 days / > 30 days | 7 天内 / 超 30 天 | 常见时限：终版账单 7 天窗口；GL 批准后 30 天未处理则取消请求 |

### 1.4 主数据 / Master Data

| 术语 English | 中文 | 说明 |
|---|---|---|
| Hospital Master | 医院主数据 | 后端（G400/Compass）与 CRM 双向人工维护；保存触发 OneData 校验 Hospital Code |
| Hospital Code | 医院代码 | 来自 G400/Compass；IB 代码校验后返回 Address Code + Vendor Code，EB 仅返回成功消息 |
| Vendor Code / Address Code | 供应商代码 / 地址代码 | IB 医院校验后由 OneData 返回并写回 CRM |
| Doctor Master | 医生主数据 | Portal 授权用户与 AHS/CRM 管理员均可创建；集成需挂医院 + 1 主专科 + 1 副专科 |
| Doctor's Hospital / Doctor's Specialty | 医生执业医院 / 医生专科 | 医生档案的关联实体；Integration Status 设为 Ready to Sync 触发集成 |
| Client Code | 客户代码 | 后端返回的医生唯一标识；新记录回写 CRM，存量记录作为集成唯一键 |
| Main Specialty / Sub-specialty | 主专科 / 副专科 | 多个副专科时，最早修改（earliest modified on）的同步到后端 |
| Portal User Master | 门户用户主数据 | Portal 与 CRM 双向创建；Portal 建的先进后端再回流 CRM，CRM 建的直接进后端 |
| Super Admin / Hospital Admin / Normal User / Assessor（Portal 角色） | 超级管理员 / 医院管理员 / 普通用户 / 审核员 | 门户用户权限矩阵中的角色（Read-Only / Create-Update / Update Self Profile 等） |
| EB Customer Benefit Update Rules | EB 客户利益更新规则 | 数据优先级：EB Customer record > EB Customer Benefit Change > CRM Configurator > Backend record；过期（Valid to expires）则停用 Change 记录 |
| EB Customer Benefit Change | EB 客户利益变更记录 | 患者搜索回传后创建的限额变更载体 |
| CRM Configurator | CRM 配置器 | 存放利益限额等配置的 CRM 配置实体 |

### 1.5 系统与集成 / Systems & Integration

| 术语 English | 中文 | 说明 |
|---|---|---|
| AHS ⚠️ | AIA 健康服务（推测 AIA Health Services） | CRM 侧运营主体的简称：AHS CRM、AHS Administrator、AHS user 等 |
| CRM (Dynamics 365) | 客户关系管理系统 | 本项目核心系统（Microsoft Dynamics 365），承载 Case、GL、审核、主数据 |
| Provider Portal | 医疗机构门户 | 医院端操作入口：患者搜索、GL 请求、账单提交、报表下载等 |
| USD (Unified Service Desk) | 统一服务桌面 | 审核员/主管使用的 CRM 客户端外壳；联络中心坐席不用 USD |
| G400 | G400 核心系统 | EB 业务后端核心（保单/理赔）；EB 集成指向 G400 |
| MCS | MCS 系统 ⚠️ | 理赔相关后端（Claim Record 创建、人工取消等），常与 G400 并列出现（MCS/G400），全称需确认 |
| Compass | Compass 核心系统 | IB 业务后端核心；IB 集成指向 Compass |
| OneData | OneData 主数据平台 | 医院主数据同步与代码校验平台 |
| ESB (Enterprise Service Bus) | 企业服务总线 | 系统间集成中间件（如医生主数据、Offline GL 的成员创建） |
| E-Referral Medi-connect | 电子转诊系统 | 外部转诊平台，与 CRM 双向集成 |
| Business Rule Engine | 业务规则引擎 | 承载 STP 判定逻辑 |
| ZGLTYP = C/B/S ⚠️ | GL 类型字段 | EB 患者搜索的后端字段判断（SAP 风格字段名），取值含义需确认 |
| ZPD01ITM = AHS ⚠️ | 后端条目字段 | EB 患者搜索显示保单详情的判断字段，含义需确认 |
| OTEM / OTNM ⚠️ | 医院网络/例外标记 | 住院与门诊请求中判断 “Hospital has OTEM?/OTNM?”，不满足则提示 Non Panel Eligibility（非网络内资格），全称需确认 |
| PHN ⚠️ | 网络医院（推测 Panel Hospital Network） | “Within PHN?” 判断是否网络内医院，需确认全称 |
| Non Panel Eligibility | 非定点（非网络）资格 | 医院不在网络内时的提示信息 |
| GL Template Generation | 担保函模板生成 | 入职前体检批准后触发 |
| SMS / PN (Push Notification) / Email Notification | 短信 / 推送通知 / 邮件通知 | GL 流程按通知矩阵（Section 5.10）触发；按 EB/IB、角色（Member/Spouse/Child/Guardian）、类型（PN/SMS）分支，用 NRIC 检索接收人 |
| NRIC | 身份证号（马来西亚/新加坡） | National Registration Identity Card，通知接收人检索键 |
| Notification Activity / Tracking Record | 通知活动记录 / 阅读追踪记录 | 通知与公告的落库记录 |
| Drop 1 / 2 / 2.1 / 2.2 / 2.3 / 3 / 3.3 / 3.3A | 交付批次 | 项目分批交付的版本标记（[Drop x – Ready for AIA]） |
| MOH (Ministry of Health) | 卫生部 | Deferment 第三方对象之一 |
| SLA 时限速记 | — | 等待期意外承保 < 30 天判断；GL 批准 30 天未动作取消；出院批准 7 天未提账单自动建 Final Bill；QMS 等待 30 秒重试 |

---

## Part 2. 整体业务框架 / Overall Business Framework

### 2.1 系统全景 / System Landscape

```
┌────────────────┐      ┌──────────────────────────┐      ┌─────────────────────┐
│ Provider Portal │ ⇄  │  Dynamics 365 CRM (AHS)   │  ⇄  │  Backend 核心系统     │
│ 医疗机构门户      │      │  Case/GL/审核/主数据       │      │  EB → G400 / MCS     │
│ 医院用户操作入口   │      │  USD（审核员/主管界面）      │      │  IB → Compass        │
└────────────────┘      │  STP 规则引擎 + QMS 派单    │      └─────────────────────┘
        ▲               └──────────┬───────────────┘                ▲
        │                          │ ESB / 集成                      │
   E-Referral 系统 ⇄ ──────────────┼─────────────── OneData（医院主数据校验）
   电子转诊平台                     │
                          SMS / PN / Email 通知引擎
```

- **Provider Portal（医院端）**：患者搜索、提交各类 GL/账单请求、查看结果、下载报表、接收公告。
- **CRM（AHS 端）**：每个请求创建为 Case → STP 自动判定或 QMS 派给 Assessor 人工审核 → 批准生成 GL / 拒绝生成 Decline Letter → 与后端同步理赔记录。
- **Backend**：EB 走 G400（部分场景 MCS），IB 走 Compass；主数据经 OneData 校验，集成经 ESB。

### 2.2 两条业务线 / Two Lines of Business

| 维度 | EB 员工福利（团体） | IB 个人福利（个人） |
|---|---|---|
| 数据结构 | Company → EB Policy → EB Plan → Policy Profile → Member；产品/利益四层挂接 | IB Policy → Policy Plan / Top Up Plan / Health Reward → Plan Code → Benefit Code；关联 Contact |
| 后端系统 | G400（/MCS） | Compass |
| 专属功能 | Maternity 产科、Procedural 操作、Open GL 开放担保函 | 现金价值抵扣保费校验（Premium Paid Date > 30 天 → Cash Value） |
| 患者搜索校验 | Member active → Policy status(IF/PE/PR) → Active plan → Underwriting code → 是否 Suspended → Product Type | Policy active → Active plan code → Cashless facilities → Within PHN |

### 2.3 GL 请求生命周期（核心主线）/ GL Request Lifecycle

**住院线 Inpatient（同一 GL + LOG#，案件互相关联）：**

```
患者搜索 Patient Search
   │
   ▼
Admission Request 入院申请 ──批准──► IGL 签发 + Activate Log
   │                                   │
   ├─► Additional GL 追加担保（新增诊断/操作，可部分批，拒条目可 Appeal）
   ├─► Top-Up 额度追加（额度不足）
   ▼
Discharge Request 出院申请（可补医生/诊断；可触发 AUC）
   │
   ├─► Amended Bill 修正账单（按审核意见改）
   ▼
Final Bill Submission 终版账单（金额 = AIA 批准额；7 天未提自动建）──► FGL
   │
   └─► Follow-Up GL（出院后复诊）──► Follow-Up Bill / Amended / Final Bill
```

**门诊线 Outpatient：** New Visit / Follow-up Visit / Procedural / Medication / Medical Check-up 每类请求各自新建 Case + 新 LOG# → OP Bill → OP Amended Bill → OP Final Bill。

**通用提交前校验链（Portal + CRM）：** Privilege Card → Utilization Balance 额度 → Waiting Period 等待期（<30 天仅意外责任）→ Within PHN 网络内 → Emergency 急诊分支 → OTEM/OTNM 医院资格 → Co-share/Deductible 患者确认 → 进入请求表单。

**案件内处理骨架（几乎所有请求复用）：**
Submit（Portal）→ Create Case（CRM）→ QMS/STP → Manual Assessment → Deferment?（补材料）→ Update Diagnosis & Procedures → System matched ICD/LOS/Value → Assess → Approve? → 批：Generate Approved GL + Generate Log Number + 后端建 Claim Record（Success/Failed → 失败人工处理）；拒：Update Decline Reason + Decline Letter → Portal 显示结果 → Appeal?（是 → 申诉流程）。

### 2.4 支撑流程 / Supporting Processes

| 流程 | 作用 | 关键点 |
|---|---|---|
| QMS 队列分配 | 派单引擎 | 队列号前缀逻辑；Deferment 回流优先找原审核员；无人可用等 30 秒；多人可用给等待最久者 |
| Deferment 延期补材料 | 向医院/第三方要信息 | 医院走 Portal 交互（Reply Deferment），第三方（Doctor/MOH）审核员人工跟进；QMS 回流派单 |
| AUC 待澄清金额 | 出院/账单金额澄清 | AUC Assessor 专岗；Query 可发 Provider 或第三方；完成后核 FGL Exclusion 并回主流程 |
| Appeal 申诉 | 对拒绝结果申诉 | 主/子案件分流；仅一次申诉；重建 Case 走 QMS |
| Claim Cancellation 理赔取消 | 取消请求/理赔 | 已提交出院或 OP 账单后不允许取消；EB 在 G400 置 CR，必要时 MCS 人工取消 + SMS 客户 |
| Case Reopen 案件重开 | 改判/修正已结案件 | 仅 CRM 侧；原案置 Cancelled-Reopen 复制新案；旧 IGL/FGL/赔付后端手工取消，无集成 |
| 通知引擎 | SMS/PN/Email | 按通知矩阵与 EB/IB、家属角色（Spouse/Child/Guardian）分支，用 NRIC 找接收人 |
| 主数据维护 | Hospital / Doctor / Portal User | 医院代码经 OneData 校验；医生集成回 Client Code；门户用户 Portal↔CRM↔Backend 三方同步 |
| 运营管理 | Supervisor Review / Coaching / Call Log / Library / Announcement / Report Request | 主管派单与辅导、坐席通话记录、知识库、公告推送、对账单生成 |

### 2.5 角色矩阵 / Role Matrix

| 角色 English | 中文 | 主要系统 | 职责 |
|---|---|---|---|
| Provider User / Portal User | 医院用户 | Provider Portal | 患者搜索、提交请求与账单、申诉、下载报表 |
| Hospital Admin | 医院管理员 | Portal | 管理本院普通用户 |
| Super Admin | 超级管理员 | Portal/CRM | 门户用户主数据最高权限 |
| Assessor | 审核员 | CRM (USD) | 案件审核、批/拒、Deferment、录 AUC |
| AUC Assessor | AUC 审核员 | CRM | 处理 AUC Query 至完成 |
| Supervisor | 主管 | CRM (USD) | 看全量案件、派单、排班、Coaching |
| AHS / CRM Administrator | AHS/CRM 管理员 | CRM | 主数据维护、Open GL 设置、公告、知识库 |
| Contact Centre Agent | 联络中心坐席 | CRM（非 USD） | 只读案件 + 创建/更新 Call Log |
| 3rd Party (Doctor / MOH) | 第三方（医生/卫生部） | 线下 | Deferment/AUC 的外部澄清对象 |

---

## Part 3. 待确认清单 / Open Questions（需要业务方补充）

1. ⚠️ **缩写全称**：AHS、MCS、OTEM、OTNM、PHN、GHS/GMT/GSP 的官方全称与业务含义。
2. ⚠️ **状态码**：Policy Status 中 IF / PE / PR 各自含义；Underwriting Code 的 4 与 7 分别代表什么。
3. ⚠️ **后端字段**：ZGLTYP（C/B/S 取值含义）、ZPD01ITM = AHS 的业务规则。