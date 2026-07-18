# AIA 医疗保险业务流程梳理：EB 与 IB

> 本文档根据已查看的约 30 个业务流程图整理。  
> 当前目标是理解业务，不涉及 Dataverse、Case 实体、插件或其他具体技术实现。  
> 文档把整个医疗保险业务拆分为两条主线：
>
> - **EB — Employee Benefits：团体保险**
> - **IB — Individual Business：个人保险**

---

# 1. 总体业务划分

```text
AIA 医疗保险业务
├── EB：Employee Benefits，团体保险
└── IB：Individual Business，个人保险
```

两类业务最终都可能进入类似的医疗处理主链：

```text
Patient Search
→ Eligibility Check
→ Medical Request
→ Assessment
→ GL / Claim
→ Billing
→ Completion
```

但二者在以下方面存在明显差异：

- 投保主体不同
- 保单及保障结构不同
- 患者资格判断规则不同
- 缴费和保单维持规则不同
- 特殊医疗业务不同
- 后端业务系统倾向不同

---

# 2. EB 与 IB 的总体对比

| 维度 | EB 团体保险 | IB 个人保险 |
|---|---|---|
| 业务全称 | Employee Benefits | Individual Business |
| 投保主体 | Company 企业 | Contact / Individual 个人 |
| 被保对象 | Member 员工及家属 | Policyholder / Insured |
| 保单类型 | 企业团体保单 | 个人保险合同 |
| 保障结构 | EB Plan、Customer Product、Customer Benefit | Policy Plan、Top-Up Plan、Plan Code |
| 核心资格判断 | Member、Policy、Plan、Benefit、Provider Network | Policy、Waiting Period、Premium、Cash Value |
| 缴费责任 | 通常由企业统一承担 | 个人直接缴费 |
| Cash Value | 通常不是核心判断 | 可能用于抵扣欠缴保费 |
| 典型特殊流程 | Maternity、Open GL、EB Benefit Configurator | Premium Arrears、Cash Value Offset |
| 主要后端倾向 | G400 | MCS / Compass |
| 最终业务结果 | GL、Bill、Claim | GL、Bill、Claim |

---

# 3. EB：Employee Benefits 团体保险

## 3.1 EB 的业务背景

EB 的基础业务关系可以先理解为：

```text
Company
└── EB Policy
    ├── EB Plan
    └── Policy Profile
        ├── Member
        ├── Customer Product
        └── Customer Benefit
```

核心业务含义：

```text
公司为员工及其家属购买团体保险
→ 员工或家属成为 Member
→ Member 按所属 Plan 享受相应 Benefit
```

因此，EB 并不是只判断“这个人有没有保险”，还要同时判断：

- 企业保单是否有效
- Member 是否有效
- Member 所属计划是否有效
- 产品及 Benefit 是否适用
- 医疗机构是否符合网络规则
- 剩余保障额度是否足够

---

# 4. EB 团体保险完整业务树

```text
EB（Employee Benefits，团体保险）
│
├── 1. 团体保险基础结构
│   │
│   ├── 1.1 Company 企业客户
│   │   └── 为员工及其家属购买团体医疗保险
│   │
│   ├── 1.2 EB Policy 团体保单
│   │   ├── 保单状态
│   │   ├── 保单有效期
│   │   ├── 是否暂停
│   │   └── 核保类别
│   │
│   ├── 1.3 EB Plan 团体保障计划
│   │   └── 区分不同员工类别或保障等级
│   │
│   ├── 1.4 Policy Profile 保单业务档案
│   │   ├── 连接保单、会员和保障配置
│   │   └── 查询保单完整业务信息的重要入口
│   │
│   ├── 1.5 Member 会员／被保员工及家属
│   │   ├── 员工本人
│   │   ├── 配偶
│   │   ├── 子女
│   │   └── 其他合资格家属
│   │
│   └── 1.6 产品与保障配置
│       ├── Product Group 产品组
│       ├── EB Customer Product Group 客户产品组
│       ├── EB Customer Product 客户产品
│       ├── Product Type 产品类型
│       ├── Benefit Group 保障组
│       ├── EB Customer Benefit Group 客户保障组
│       ├── EB Customer Benefit 客户实际保障
│       └── Benefit Code 标准保障代码
│
├── 2. 医疗服务参与方
│   │
│   ├── 2.1 Patient 患者
│   │   └── 当前实际接受医疗服务的 Member
│   │
│   ├── 2.2 Provider 医疗服务机构
│   │   ├── Hospital 医院
│   │   ├── Clinic 诊所
│   │   └── 其他合作医疗机构
│   │
│   ├── 2.3 Doctor 医生
│   │   ├── 所属医院
│   │   ├── Main Specialty 主专科
│   │   └── Sub-specialty 子专科
│   │
│   └── 2.4 Provider Portal 医疗机构门户
│       ├── 查询患者
│       ├── 查看保单与保障
│       ├── 提交医疗请求
│       ├── 回复补件
│       ├── 提交账单
│       ├── 查看处理结果
│       └── 下载报告
│
├── 3. Patient Search 患者查询
│   │
│   ├── 3.1 选择保险类型
│   │   └── Corporate / EB
│   │
│   ├── 3.2 搜索患者
│   │   ├── Member Number
│   │   ├── Patient Name
│   │   ├── Identification Number
│   │   ├── Policy Number
│   │   └── 其他搜索条件
│   │
│   ├── 3.3 搜索结果校验
│   │   ├── Member Active?
│   │   ├── Policy Status Eligible?
│   │   │   └── IF / PE / PR 等允许状态
│   │   ├── Active Plan?
│   │   ├── Underwriting Code Allowed?
│   │   ├── Policy Suspended?
│   │   └── Product Type Eligible?
│   │
│   └── 3.4 查询结果
│       ├── 无有效会员 → 显示提示
│       └── 找到有效会员
│           ├── 显示患者列表
│           └── 查看 Policy Details
│
├── 4. Request Creation Eligibility 请求创建资格判断
│   │
│   ├── 4.1 Privilege Card?
│   │   └── 特权卡可能允许快速进入申请
│   │
│   ├── 4.2 Utilization Balance
│   │   ├── 检查剩余保障额度
│   │   └── 额度不足则停止申请
│   │
│   ├── 4.3 Waiting Period
│   │   ├── 是否仍在等待期
│   │   ├── 等待期天数
│   │   └── 意外伤害可能适用例外
│   │
│   ├── 4.4 PHN / Panel Eligibility
│   │   ├── 医院是否属于合资格网络
│   │   └── 非合作医院可能需要特殊处理
│   │
│   ├── 4.5 Emergency Case?
│   │   └── 急诊可能适用不同规则
│   │
│   ├── 4.6 Hospital Eligibility
│   │   ├── OTEM
│   │   ├── OTNM
│   │   └── 具体全称仍待后续资料确认
│   │
│   ├── 4.7 Co-share / Deductible
│   │   ├── Co-share 共付比例
│   │   ├── Deductible 免赔额
│   │   └── Patient Agrees?
│   │
│   └── 4.8 资格通过
│       └── 进入医疗请求表单
│
├── 5. EB Inpatient 住院业务
│   │
│   ├── 5.1 Admission Request 入院申请
│   │   │
│   │   ├── 业务目的
│   │   │   └── 为本次住院申请初始医疗授权和 GL
│   │   │
│   │   ├── 提交内容
│   │   │   ├── Admission Information
│   │   │   ├── Diagnosis 诊断
│   │   │   ├── Procedures 医疗项目
│   │   │   ├── ICD Code
│   │   │   ├── LOS 预计住院天数
│   │   │   └── Supporting Documents
│   │   │
│   │   ├── 处理方式
│   │   │   ├── QMS 排队
│   │   │   ├── Manual Assessment 人工审核
│   │   │   ├── Deferment 补件
│   │   │   └── 审核建议
│   │   │
│   │   └── 结果
│   │       ├── Approved
│   │       │   ├── Generate Approved GL
│   │       │   ├── Generate LOG Number
│   │       │   └── 住院流程正式开始
│   │       └── Declined
│   │           ├── Decline Reason
│   │           ├── Decline Letter
│   │           └── Appeal
│   │
│   ├── 5.2 Additional GL Request 追加医疗项目申请
│   │   ├── 住院期间增加新的诊断、检查或治疗项目
│   │   ├── 可增加 Additional Diagnosis / Procedure
│   │   └── 结果：全部批准、部分批准或全部拒绝
│   │
│   ├── 5.3 Top-Up Request 增加批准金额
│   │   ├── 住院时间延长
│   │   ├── 药物或治疗费用增加
│   │   ├── 原批准金额不足
│   │   └── STP 自动判断或转人工审核
│   │
│   ├── 5.4 Discharge Request 出院申请
│   │   ├── 患者准备出院
│   │   ├── 医院补充诊断、医生、治疗及费用
│   │   ├── Validate Charges
│   │   ├── AUC Required?
│   │   ├── Draft GL
│   │   └── Final GL
│   │
│   ├── 5.5 Amended Bill Request 修正账单
│   │   ├── 修改金额或费用项目
│   │   ├── 重新审核
│   │   └── 重新生成 Final GL
│   │
│   ├── 5.6 Final Bill Submission 最终账单
│   │   ├── 医院提交最终账单
│   │   ├── 金额与最终批准金额匹配
│   │   ├── 更新后端 Claim Status
│   │   └── 出院批准超过7天未提交时可自动触发
│   │
│   └── 5.7 Follow-Up Post-Hospitalization 出院后随访
│       ├── Follow-Up GL Request
│       ├── 新 GL / 新 LOG Number
│       ├── Follow-Up Bill Submission
│       ├── Follow-Up Amended Bill
│       └── Follow-Up Final Bill
│
├── 6. EB Outpatient 门诊业务
│   ├── New Visit 新门诊
│   ├── Follow-Up Visit 复诊
│   ├── Medication 药物申请
│   ├── Medical Check-Up 体检
│   ├── Health Screening 健康筛查
│   ├── Procedural Request 医疗操作申请
│   └── 门诊账单
│       ├── OP Bill Submission
│       ├── OP Amended Bill
│       └── OP Final Bill Submission
│
├── 7. EB Special Medical Processes 特殊医疗流程
│   ├── Maternity Request 生育申请
│   ├── Pre-Employment Screening 入职体检
│   ├── E-Referral 电子转诊
│   ├── Open GL
│   └── Offline GL
│
├── 8. Assessment & Decision 审核与决策
│   ├── STP 自动审核
│   ├── QMS 队列管理
│   ├── Manual Assessment 人工审核
│   ├── Deferment 补件
│   ├── AUC 金额澄清
│   ├── Appeal 申诉
│   ├── Cancellation 取消
│   └── Reopen 业务重开
│
├── 9. GL 与 Claim 结果
│   ├── GL 生命周期
│   │   ├── Draft GL
│   │   ├── Approved GL
│   │   ├── Updated GL
│   │   ├── Final GL
│   │   └── Declined GL
│   │
│   └── Claim / Request 状态
│       ├── Request Received
│       ├── Bill Received
│       ├── In Queue
│       ├── Processing Now
│       ├── Deferment Sent
│       ├── Deferment Responded
│       ├── Pending Medical Audit
│       ├── Medical Audit Responded
│       ├── Approved
│       ├── Declined
│       ├── Completed
│       ├── Closed
│       └── Cancelled
│
├── 10. 沟通与服务支持
│   ├── Notification
│   ├── Contact Centre Call Log
│   ├── Announcement
│   ├── Knowledge Library
│   └── Report Request
│
└── 11. EB 业务管理与主数据支持
    ├── Hospital Master
    ├── Doctor Master
    ├── Portal User Master
    ├── EB Benefit Configurator
    ├── Queue Assessor Setup
    └── Supervisor & Coaching
```

---

## 4.1 EB 主业务链

```text
Company
→ EB Policy
→ EB Plan / Policy Profile
→ Member
→ Product / Benefit
→ Patient Search
→ Eligibility Check
→ Medical Request
   ├── Inpatient
   ├── Outpatient
   ├── Maternity
   ├── Procedure
   ├── E-Referral
   └── Screening
→ STP / QMS / Manual Assessment
→ Approved / Declined / Deferment
→ GL
→ Treatment
→ Discharge / Bill
→ Final GL
→ Claim Completed
→ Notification / Report
```

## 4.2 EB 住院主链

```text
Admission
→ Additional GL / Top-Up
→ Treatment
→ Discharge
→ Amended Bill / Final Bill
→ Final GL
→ Completed
```

## 4.3 EB 门诊主链

```text
New Visit / Follow-Up / Medication / Procedure
→ Assessment
→ GL
→ OP Bill
→ OP Amended Bill / OP Final Bill
→ Completed
```

## 4.4 EB 异常与辅助处理链

```text
Normal Assessment
├── Need More Information → Deferment
├── Amount Question → AUC
├── Declined → Appeal
├── Wrong Request → Cancellation
└── Closed Result Needs Correction → Reopen
```

---

# 5. IB：Individual Business 个人保险

## 5.1 IB 的业务背景

IB 的基础业务关系可以理解为：

```text
Contact
└── Policy Profile
    └── IB Policy
        ├── IB Policy Plan
        ├── IB Top-Up Plan
        ├── IB Health Reward
        └── IB Plan Code
            └── IB Plan Benefit Code
                └── IB Benefit Code
```

核心业务含义：

```text
个人购买保险
→ 个人保单下拥有 Plan
→ Plan 对应 Benefit
→ 医疗请求直接基于个人保险合同进行判断
```

IB 不依赖 Company 和企业 Member 结构。

---

# 6. IB 个人保险完整业务树

```text
IB（Individual Business，个人保险）
│
├── 1. 个人保险基础结构
│   │
│   ├── 1.1 Contact 客户／个人
│   │   ├── Policyholder 保单持有人
│   │   ├── Insured 被保人
│   │   └── Patient 实际就医患者
│   │
│   ├── 1.2 IB Policy 个人保单
│   │   ├── Policy Number
│   │   ├── Policy Status
│   │   ├── Effective Date
│   │   ├── Premium Paid Date
│   │   ├── Outstanding Premium
│   │   ├── Cash Value
│   │   └── Cashless Eligibility
│   │
│   ├── 1.3 Policy Profile 保单业务档案
│   │   ├── 连接 Contact 与 IB Policy
│   │   ├── 汇总当前保单信息
│   │   ├── 汇总计划和保障
│   │   └── 作为查看保单详情的入口
│   │
│   ├── 1.4 IB Policy Plan 基础保险计划
│   │   ├── 保单持有的主要计划
│   │   ├── 关联 IB Plan Code
│   │   └── 决定主要保障范围
│   │
│   ├── 1.5 IB Top-Up Plan 附加／补充计划
│   │   ├── 在基础计划上增加保障
│   │   └── 与住院流程中的 Top-Up Request 不同
│   │
│   ├── 1.6 IB Health Reward 健康奖励
│   │   └── 具体规则尚未从流程图中展开
│   │
│   └── 1.7 Plan 与 Benefit 结构
│       ├── IB Plan Code
│       ├── IB Plan Benefit Code
│       └── IB Benefit Code
│
├── 2. 医疗服务参与方
│   ├── Patient 患者
│   ├── Provider 医疗服务机构
│   ├── Doctor 医生
│   └── Provider Portal 医疗机构门户
│
├── 3. IB Patient Search 患者查询
│   │
│   ├── 选择 Individual / IB
│   ├── Patient Search
│   ├── Policy Active?
│   ├── Active Plan Code?
│   ├── Cashless Facilities?
│   ├── Within PHN?
│   └── Display Patient List / Policy Details
│
├── 4. IB Request Submission Eligibility 请求创建资格
│   │
│   ├── 4.1 Waiting Period
│   │   ├── Within Waiting Period?
│   │   ├── 疾病保障可能受限
│   │   └── Accident-related Conditions 可能例外
│   │
│   ├── 4.2 Hospital Acceptance
│   │   └── Hospital Agrees?
│   │
│   ├── 4.3 Premium Status
│   │   ├── Premium Paid Date
│   │   ├── Outstanding Premium
│   │   └── 是否欠费超过30天
│   │
│   ├── 4.4 Cash Value
│   │   ├── Has Cash Value?
│   │   └── 是否足以抵扣欠缴保费
│   │
│   ├── 4.5 Utilization Balance
│   │   └── 检查剩余保障额度
│   │
│   ├── 4.6 Co-share / Deductible
│   │   ├── 提示患者承担金额
│   │   └── Patient Agrees?
│   │
│   └── 4.7 资格通过
│       └── Go to New Request Form
│
├── 5. IB 医疗请求分类
│   ├── Inpatient 住院请求
│   ├── Outpatient 门诊请求
│   └── Procedural Request 医疗操作请求
│       └── 具体可适用范围仍需结合产品配置确认
│
├── 6. IB Inpatient 住院业务框架
│   │
│   ├── 6.1 Admission / Initial GL
│   │   ├── 医院提交住院请求
│   │   ├── 进入自动或人工审核
│   │   ├── Approved → 生成 GL
│   │   └── Declined → 可进入 Appeal
│   │
│   ├── 6.2 Treatment Period
│   │   ├── 可能发生费用增加
│   │   ├── 可能发生治疗项目变化
│   │   └── 可能需要 Deferment
│   │
│   ├── 6.3 Discharge
│   │   ├── 医院提交费用
│   │   ├── 医疗及费用审核
│   │   ├── AUC if Required
│   │   ├── Draft GL
│   │   └── Final GL
│   │
│   ├── 6.4 Bill
│   │   ├── Bill Submission
│   │   ├── Amended Bill
│   │   └── Final Bill
│   │
│   └── 6.5 Completion
│       ├── 更新关联请求
│       ├── 更新后端理赔记录
│       └── Claim Completed / Closed
│
├── 7. IB Outpatient 门诊业务
│   │
│   ├── 7.1 门诊请求入口
│   │   ├── New Visit
│   │   ├── Follow-Up Visit
│   │   ├── Medication
│   │   ├── Medical Check-Up
│   │   └── Health Screening
│   │
│   ├── 7.2 门诊请求处理
│   │   ├── STP
│   │   ├── QMS
│   │   ├── Manual Assessment
│   │   └── Deferment if Required
│   │
│   ├── 7.3 决策结果
│   │   ├── Approved → GL / LOG
│   │   └── Declined → Appeal
│   │
│   └── 7.4 门诊账单
│       ├── OP Bill Submission
│       ├── OP Amended Bill
│       ├── OP Final Bill Submission
│       ├── AUC if Required
│       └── Final GL / Completion
│
├── 8. Assessment & Decision 审核与决策
│   ├── STP 自动审核
│   ├── QMS 队列管理
│   ├── Manual Assessment 人工审核
│   ├── Deferment 补件
│   ├── AUC 金额澄清
│   ├── Appeal 申诉
│   ├── Cancellation 取消
│   └── Reopen 业务重开
│
├── 9. GL 与 Claim 结果
│   │
│   ├── GL 生命周期
│   │   ├── Draft GL
│   │   ├── Approved GL
│   │   ├── Updated GL
│   │   ├── Final GL
│   │   └── Declined GL
│   │
│   ├── Request / Claim 状态
│   │   ├── Request Received
│   │   ├── Bill Received
│   │   ├── Open
│   │   ├── In Queue
│   │   ├── Processing Now
│   │   ├── Deferment Sent
│   │   ├── Deferment Responded
│   │   ├── Pending Medical Audit
│   │   ├── Medical Audit Responded
│   │   ├── Approved
│   │   ├── Declined
│   │   ├── Completed
│   │   ├── Closed
│   │   └── Cancelled
│   │
│   └── IB 后端处理
│       ├── MCS 偏向 IB Claim Processing
│       ├── Compass 偏向 IB Provider / Doctor 主数据
│       └── 处理结果同步回 CRM 与 Portal
│
├── 10. IB 主数据与集成支持
│   ├── Hospital Master
│   ├── Doctor Master
│   ├── Portal User Master
│   └── Integration
│       ├── Provider Portal
│       ├── CRM
│       ├── MCS
│       ├── Compass
│       ├── OneData
│       └── Notification Services
│
└── 11. 沟通与服务支持
    ├── Notification
    ├── Contact Centre Call Log
    ├── Announcement
    ├── Knowledge Library
    └── Report Request
```

---

## 6.1 IB 主业务链

```text
Contact / Insured
→ IB Policy
→ Policy Plan / Top-Up Plan
→ Plan Code / Benefit Code
→ Patient Search
→ Policy Active Check
→ Waiting Period Check
→ Premium Status Check
→ Cash Value Check
→ Utilization Balance Check
→ Medical Request
   ├── Inpatient
   └── Outpatient
→ STP / QMS / Manual Assessment
→ Approved / Declined / Deferment
→ GL
→ Treatment
→ Bill
→ Final GL
→ Claim Completed
→ Notification / Report
```

## 6.2 IB 请求资格链

```text
Policy Active
→ Active Plan Code
→ Cashless Facility
→ Waiting Period
→ Premium Paid Date
→ Outstanding Premium
→ Cash Value
→ Utilization Balance
→ Co-share / Deductible
→ Patient Consent
```

## 6.3 IB 医疗处理链

```text
New Medical Request
→ Automatic or Manual Assessment
→ Approved GL
→ Treatment
→ Bill Submission
→ Final Amount Confirmation
→ Final GL
→ Completed
```

## 6.4 IB 异常与辅助处理链

```text
Normal Assessment
├── Missing Information → Deferment
├── Amount Question → AUC
├── Declined → Appeal
├── Wrong Request → Cancellation
└── Closed Result Needs Correction → Reopen
```

---

# 7. 两条业务主线的最终总结

## 7.1 EB 一句话理解

> EB 是以企业福利计划为中心，通过 Company、Policy、Member、Plan 和 Benefit 的组合，判断员工及其家属能否获得当前医疗服务和赔付。

## 7.2 IB 一句话理解

> IB 是以个人保险合同为中心，通过检查保单状态、等待期、保费情况、现金价值和剩余保障额度，决定个人医疗请求是否可以获得授权和赔付。

## 7.3 最简对照

```text
EB：
公司给员工配置了什么福利？

IB：
这个人的个人保险合同现在是否有效，
并且是否满足本次医疗赔付条件？
```

---

# 8. 当前仍待后续确认的术语

以下术语的整体业务位置已经明确，但完整定义仍需后续资料确认：

- **PHN**
- **OTEM**
- **OTNM**
- **IF / PE / PR**
- 某些 **Product Type Code**
- IB 可使用的具体 Procedural Request 范围
- IB 住院中的 Additional GL / Top-Up 是否与 EB 完全一致
