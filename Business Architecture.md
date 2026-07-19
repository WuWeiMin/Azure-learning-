# 医疗保险担保函系统 — 总体业务架构
# Medical Insurance Guarantee Letter System — Overall Business Architecture

> 基于 30 个业务流程整理；关键词汇 English + 中文 双语。

---

## 0. 全景总览 / Big Picture

```
医疗保险 CRM 系统 (Medical Insurance CRM)
│
├── 1. 主数据管理 (Master Data Management)
├── 2. 患者与资格 (Patient & Eligibility)
├── 3. 请求生命周期 (Request Lifecycle)
│      ├── 请求创建 (Request Creation)
│      ├── 请求处理 (Request Processing)
│      └── 请求收尾 (Request Closure)
├── 4. 审核作业 (Assessment Operations)
├── 5. 运营支持 (Operations Support)
└── 6. 通知与集成 (Notification & Integration)
```

---

## 1. 主数据管理 / Master Data Management

```
主数据 (Master Data)
│
├── Hospital Master (医院主数据)
│      ├── Hospital Code (医院代码) ── 经主数据平台校验
│      ├── Vendor Code (供应商代码)     ← 仅 IB 回写
│      └── Address Code (地址代码)      ← 仅 IB 回写
│
├── Doctor Master (医生主数据)
│      ├── Doctor's Hospital (执业医院)
│      ├── Main Specialty (主专科) + Sub-specialty (副专科)
│      ├── Integration Status = Ready to Sync (集成状态：待同步)
│      └── Client Code (客户代码) ── 后端返回的唯一标识
│
├── Portal User Master (门户用户主数据)
│      ├── Super Admin (超级管理员)
│      ├── Hospital Admin (医院管理员)
│      ├── Normal User (普通用户)
│      └── Assessor (审核员)
│
└── 产品与利益配置 (Product & Benefit Configuration)
       ├── EB 团体线
       │     ├── Product Group (产品组) → Product Type (产品类型)
       │     ├── Benefit Group (利益组) → Benefit Code (利益代码)
       │     └── EB Customer Benefit Update Rules (EB 客户利益更新规则)
       │           优先级：Customer record > Benefit Change > Configurator > Backend
       └── IB 个人线
             └── IB Plan Code (计划代码)
                   └── IB Plan Benefit Code (计划利益代码)
                         └── IB Benefit Code (利益代码)
```

### 保单数据层级 / Policy Data Hierarchy

```
EB (Employee Benefit 员工福利·团体险)          IB (Individual Benefit 个人福利·个人险)
Company (公司)                                Contact (个人客户)
 └── EB Policy (团体保单)                      └── Policy Profile (保单档案)
      ├── EB Plan (计划)                            └── IB Policy (个人保单)
      └── Policy Profile (保单档案)                      ├── IB Policy Plan (保单计划)
           └── Member (成员)                             ├── IB Top-Up Plan (加购计划)
                                                        └── IB Health Reward (健康奖励)
```

---

## 2. 患者与资格 / Patient & Eligibility

```
患者搜索 (Patient Search)
│
├── Portal Patient Search (门户患者搜索)
│      ├── EB 分支 (Corporate)
│      │     ├── Member Active? (成员有效?)
│      │     ├── Policy Status (保单状态)
│      │     ├── Active Plan (计划有效?)
│      │     ├── Underwriting Code (核保代码)
│      │     ├── Policy Suspended? (保单暂停?)
│      │     └── Product Type (产品类型)
│      └── IB 分支 (Individual)
│            ├── Policy Active? (保单有效?)
│            ├── Active Plan Code (计划代码有效?)
│            ├── Cashless Facilities? (支持直付?)
│            └── Within PHN? (是否网络内医院?)
│
└── CRM Patient Search (CRM 患者搜索)
       ├── Search Criteria (搜索条件：保单号/其他)
       ├── Policy Status Filter (状态筛选：Active / All)
       └── Redirect to Policy Profile (跳转保单档案)
```

---

## 3. 请求生命周期 / Request Lifecycle

### 3.1 请求创建 / Request Creation

```
请求创建 (Request Creation)
│
├── 创建前校验规则 (Request Creation Rules)
│      ├── EB 校验链
│      │     ├── Privilege Card (特权卡 → 跳过额度检查)
│      │     ├── Utilization Balance (使用额度余额)
│      │     ├── Waiting Period (等待期 → <30天仅承保意外)
│      │     ├── Within PHN (网络内医院)
│      │     ├── Emergency Case (急诊例外)
│      │     ├── Hospital OTEM / OTNM (医院网络资格)
│      │     │      └── 否则 Non Panel Eligibility (非定点资格) 终止
│      │     └── Co-share / Deductible (共担/免赔 → 患者同意)
│      └── IB 校验链 (住院+门诊合并)
│            ├── Waiting Period (等待期 → 仅意外相关)
│            ├── Premium Paid Date > 30 Days (保费缴纳超30天?)
│            │      └── Cash Value (现金价值) 足以抵扣欠缴保费?
│            ├── Utilization Balance (使用额度余额)
│            └── Co-share / Deductible (共担/免赔 → 患者同意)
│
├── 住院请求族 (Inpatient Case Family) ── 同一 GL + LOG#，案件互相关联
│      Admission Request (入院申请) ── 起点，签发 IGL (初始担保函)
│       ├── Additional GL Request (追加担保申请 ── 新增诊断/操作，可部分批)
│       ├── Top-Up Request (额度追加申请 ── 批准金额不足)
│       ├── Discharge Request (出院申请 ── 结算阶段，可触发 AUC)
│       ├── Amended Bill Request (修正账单申请)
│       ├── Final Bill Submission (终版账单 ── 金额=批准额；7天未提自动创建) → FGL (最终担保函)
│       └── Follow-Up GL Request (复诊担保申请 ── 出院后治疗)
│             └── Follow-Up Bill Submission (复诊账单提交)
│
├── 门诊请求 (Outpatient Requests) ── 每类新 Case + 新 LOG#
│      ├── New Visit (新就诊)
│      ├── Follow-up Visit (复诊)
│      ├── Procedural (操作/手术) ── 仅 EB
│      ├── Medication (用药)
│      ├── Medical Check-up / Health Screening (体检/健康筛查)
│      └── OP Bill (门诊账单) → OP Amended Bill (修正) → OP Final Bill (终版)
│
├── 专项请求 (Special Requests)
│      ├── Maternity Request (产科申请) ── 仅 EB；按 Reason of Visit 分住院/门诊
│      ├── Procedural Request (操作申请) ── 仅 EB；Appeal/Imaging/First Category 分流
│      ├── Pre-Employment Screening (入职前体检) ── 批准生成 GL Template (担保函模板)
│      └── E-Referral (电子转诊)
│            ├── E-Referral Request Submission (转诊请求提交)
│            └── E-Referral Search (转诊查询 ── Draft 草稿 / Submitted 已提交)
│
└── 特殊担保函 (Special GL)
       ├── Open GL (开放担保函) ── 仅 EB；白名单保单+医院，绕过额度检查
       └── Offline GL (线下担保函) ── 核心系统无成员信息，邮件人工建档
```

### 3.2 请求处理 / Request Processing

```
请求处理 (Request Processing)  ── 所有请求共用骨架
│
├── Create Case (创建案件) ── 每个请求 = 一个 Case
├── STP (Straight-Through Processing 直通式处理) ── 规则引擎自动判定
├── QMS (Queue Assignment 队列分配)
│      ├── Generate QMS Number with Prefix Logic (前缀逻辑生成队列号)
│      ├── Priority & Queue (优先级与队列)
│      ├── Deferment 回流 → 找上次同一 Assessor (原审核员优先)
│      ├── Assessor Available? (审核员可用?) ── 否则等 30 秒重试
│      └── Assign to Longest Waiting (派给等待最久的审核员)
│
├── Manual Assessment (人工审核)
│      ├── Update Diagnosis & Procedures (更新诊断与操作)
│      ├── System Matched ICD / LOS / Value (系统匹配：诊断码/住院天数/金额)
│      ├── Assess Suggested Result (评估系统建议)
│      └── Approve? (批准?)
│            ├── Yes → Generate Approved GL (生成批准担保函)
│            │         → Generate Log Number (生成日志号)
│            │         → Create/Update Claim Record in Backend (后端建理赔记录)
│            │               └── Success / Failed? ── 失败进 Failed List 人工补录
│            └── No  → Update Decline Reason (更新拒绝原因)
│                      → Generate Decline Letter (生成拒绝函)
│
└── 处理中的中断 (Interruptions)
       ├── Deferment (延期补材料)
       │      ├── 对医院 → Portal 交互 Reply Deferment (回复延期)
       │      ├── 对第三方 (Doctor 医生 / MOH 卫生部) → 审核员人工跟进
       │      └── 状态：Sent → Received → Responded → Completed / Cancelled
       └── AUC (Amount Under Clarification 待澄清金额)
              ├── 触发：出院/门诊账单/修正账单/复诊账单
              ├── AUC Query (质询) → Provider (医院) 或 3rd Party (第三方)
              ├── AUC Query Line (质询明细行)
              └── 完成 → Update FGL Exclusion (更新最终担保函除外项) → 回主流程
```

### 3.3 请求收尾 / Request Closure

```
请求收尾 (Request Closure)
│
├── Appeal Request (申诉申请)
│      ├── Main Request / Sub-case (主案/子案分流)
│      ├── First Appeal Only (仅允许一次申诉)
│      └── Create New Case → Route to QMS (重建案件重新派单)
│
├── Claim Cancellation (理赔取消)
│      ├── Main / Sub Request (主/子请求判断)
│      ├── 已提交出院或门诊账单 → Cancellation Not Allowed (不允许取消)
│      ├── EB → Cancel Claim in Backend (后端取消，状态=CR)
│      ├── IB → Manual Cancel (人工取消) + Trigger SMS to Customer (短信通知客户)
│      └── Failed → Manual Update Backend (失败人工更新后端)
│
└── Case Reopen (案件重开) ── 仅限已批准 FGL 类案件
       ├── 场景1：Change Declined Decision (改判拒绝决定)
       ├── 场景2：Amend Approved Case (修正已批准案件)
       ├── 原案 → Cancelled-Reopen (作废) + Copy as New Case (复制为新案)
       └── 旧 IGL / FGL / Claim Pay-out → 后端手工取消 (无集成)
```

---

## 4. 审核作业 / Assessment Operations

```
审核作业 (Assessment Operations)
│
├── Assessor (审核员) ── USD (Unified Service Desk 统一服务桌面) 作业
├── AUC Assessor (AUC 审核员) ── 专岗处理待澄清金额
├── Supervisor (主管)
│      ├── Supervisor Review & Action Item (主管审阅与行动项)
│      │      ├── Self (自领案件)
│      │      └── Assign to Assessor (指派给审核员)
│      ├── Queue Assessor Setup (队列审核员设置)
│      │      ├── Create New Assessor (创建审核员)
│      │      ├── Manual Edit Schedule (手工排班)
│      │      └── Upload Schedule from Excel (Excel 上传排班)
│      └── Coaching (辅导)
│            ├── Part 1: Supervisor Create Coaching (主管创建辅导记录)
│            └── Part 2: Assessor View & Complete (审核员查看并完成)
└── 决策要素 (Decision Inputs)
       ├── ICD (诊断编码) / LOS (Length of Stay 住院天数) / Value (金额)
       ├── Deferment (延期) / Approve (批准) / Decline (拒绝)
       └── FGL Exclusion (最终担保函除外责任)
```

---

## 5. 运营支持 / Operations Support

```
运营支持 (Operations Support)
│
├── Contact Centre Call Log (联络中心通话记录)
│      ├── Contact Centre Agent (坐席) ── CRM 界面（非 USD）
│      ├── 案件只读 (Read-Only Cases)，不可访问 AUC Query
│      └── Create / Update Call Log (创建/更新通话记录)
│
├── Library / Knowledge Base (知识库)
│      └── Create → Review & Approve → Publish (创建→审批→发布，仅存于 CRM)
│
├── Announcement (公告)
│      ├── CRM 维护，有效期内推送到 Provider Portal (门户)
│      └── User Reads → Tracking Record (阅读追踪记录)
│
└── Report Request (报表申请)
       ├── Statement of Account (对账单)
       ├── Select Report Criteria (选择报表条件)
       └── Generate → Status Completed → Download (生成→完成→下载)
```

---

## 6. 通知与集成 / Notification & Integration

```
通知与集成 (Notification & Integration)
│
├── 通知引擎 (Notification Engine)
│      ├── 渠道：SMS (短信) / PN (Push Notification 推送) / Email (邮件)
│      ├── 触发：Case Created / Updated + Condition Matching (条件匹配)
│      ├── Notification Setting & Template (通知设置与模板)
│      ├── EB → 按 Relationship (关系) 分支：
│      │       Member (成员) / Spouse (配偶) / Child (子女) / Guardian (监护人)
│      ├── IB → 按 Role (角色) 分支：Self (本人) / Others (他人)
│      ├── NRIC (身份证号) ── 接收人检索键
│      └── Notification Activity (通知活动记录)
│
└── 系统集成 (System Integration)
       ├── Provider Portal (医疗机构门户) ⇄ CRM
       ├── CRM ⇄ Backend (后端核心)
       │      ├── EB → G400 (/MCS)
       │      └── IB → Compass
       ├── ESB (Enterprise Service Bus 企业服务总线) ── 集成中间件
       ├── OneData (主数据平台) ── 医院代码校验
       ├── E-Referral System (电子转诊系统)
       └── 失败兜底 (Failure Handling)
              └── Success/Failed? → Filter Failed List (失败清单) → Manual Create/Update (人工补录)
```

---

## 7. 一条主线贯穿全图 / The Golden Thread

```
Patient Search (患者搜索)
   → Eligibility Check (资格校验)
      → GL Request (担保函请求)
         → Case + STP/QMS (建案与派单)
            → Assessment (审核：批/拒/延)
               → IGL 签发 (初始担保函)
                  → 住院中：Additional GL / Top-Up (追加)
                     → Discharge (出院) [可触发 AUC 澄清]
                        → Bill: Amended → Final (账单修正→终版)
                           → FGL (最终担保函) + Claim (理赔落账)
                              → Follow-Up (复诊) / Appeal (申诉) /
                                 Cancellation (取消) / Reopen (重开)
```

**四个关键时限 / Four Key Timers**
- Waiting Period < 30 天 → 仅承保意外 (Accident only)
- GL 批准后 30 天未动作 → 系统取消请求 (Auto cancel)
- 出院批准后 7 天未提账单 → 自动创建 Final Bill (Auto create)
- QMS 无可用审核员 → 30 秒等待重试 (Retry)
