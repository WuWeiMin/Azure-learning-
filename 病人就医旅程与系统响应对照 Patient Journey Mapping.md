# 病人就医旅程 × 系统响应对照（EB / IB 双线）
# Patient Journey × System Response Mapping (EB / IB)

> 前台（Front-stage）：病人和医院看到的现实流程（来自客户旅程材料）
> 后台（Back-stage）：CRM 系统内对应触发的 30 个业务流程
> 关键词汇 English + 中文 双语呈现

---

## 0. 客户旅程材料带来的新词汇 / New Vocabulary from Customer Journey

| 术语 English | 中文 | 说明 |
|---|---|---|
| Panel Hospital / Panel Clinic | 定点（网络内）医院 / 诊所 | 即系统流程中 Within PHN (网络内) 判断的现实对应物 |
| Platinum Hospital | 白金级定点医院 | 持 GL 入院可**免押金**的高级别网络医院 |
| Medical eCard | 电子医疗卡 | 病人在医院前台出示的身份凭证 |
| Customer App (AIA+) | 客户手机 App | 病人接收 GL 结果、查看电子卡的入口 —— 对应系统的 **PN (Push Notification 推送通知)** |
| PAF (Pre-Authorisation Form) | 预授权表格 | 主治专科医生填写的入院预授权表，随 IGL 申请一并提交（Submit IGL with PAF） |
| e-Referral Letter | 电子转诊函 | EB 特有前置：定点诊所开具，**30 天有效期**（自签发日起） |
| IGL (Initial Guarantee Letter) | 初始担保函 | 入院前预授权通过后签发 |
| FGL (Final Guarantee Letter) | 最终担保函 | 保险公司对住院费用作出理赔决定后签发 |
| Planned Admission | 计划性入院 | 三种入院方式之一 |
| Emergency Admission | 急诊入院 | 对应系统中 Emergency Case (急诊) 分支 |
| Daycare Procedure | 日间手术/治疗 | 当日出入院，或住院 ≥6 小时且 <24 小时的预约手术 |
| Hospital Deposit | 医院押金 | 系统外环节；有 GL 可减少，白金医院免收 |
| Co-insurance / Co-takaful / Deductible | 共保 / 共同保障(回教保险) / 免赔额 | 病人自付部分，对应系统 Co-share/Deductible 确认节点 |
| Non-payable Items | 不可赔付项目 | FGL 中除外的费用，医院直接向病人收取 |

---

## 1. EB 员工福利（团体险）就医全旅程 / EB Patient Journey

> 人物设定：某公司员工 Member（成员），持公司团体保单。

### 前台旅程（病人视角，7 步）

```
STEP 1  到定点诊所拿电子转诊函 (Obtain e-Referral from Panel Clinic)
        └── 批准的 GL 推送到手机 App；转诊函 30 天内有效
STEP 2  到医院/专科诊所，出示 GL 或电子医疗卡 (Show GL / e-Medical Card)
STEP 3  接受门诊治疗 (Outpatient Treatment) ── 开药/检查
STEP 4  专科医生判断需住院 → 填写 PAF 预授权表 → 医院提交 IGL 申请
STEP 5  保险公司审核 PAF → 签发或拒绝 IGL (Issue Guarantee Letter)
STEP 6  按 PAF 治疗方案住院 (Hospitalisation per PAF)
STEP 7  出院：医院整理账单与出院文件提交保险公司 → FGL
        └── 不可赔付项目由医院当场向病人收取
```

### 前台 × 后台对照表

| 病人看到的（Front-stage） | 系统里发生的（Back-stage 对应流程） |
|---|---|
| **STEP 1** 诊所开电子转诊函，GL 推到手机 App | **E-Referral Request (1.9)**：诊所在转诊系统录入 → CRM 取主数据 → Create Case → **STP** 判定 → 批准则 **Create E-Referral GL** → **通知引擎 (1.29)** 以 PN 推送到客户 App；30 天有效期对应"GL 批准后 30 天未动作系统取消"规则 |
| **STEP 2** 前台出示 eCard 登记 | **Portal Patient Search – EB (1.2.1)**：医院在门户搜索患者 → Member active / Policy status / Active plan / Underwriting code / Suspended / Product Type 六连校验 → 显示保单详情；若有转诊 GL，Portal 执行 **Activate E-Referral GL → New Visit Process** |
| **STEP 3** 门诊看诊、开药、检查 | **Outpatient Requests (1.6)**：New Visit / Medication / Procedural 各自建 Case + 新 LOG# → STP/QMS → 审核 → Approved Draft GL；后续 **OP Bill Submission (1.6.2)** 结算 |
| **STEP 4** 医生填 PAF，医院提交住院申请 | **Request Creation Rules – EB Inpatient (1.3.1)**：Privilege Card → Utilization Balance → Waiting Period(<30天仅意外) → PHN → Emergency → OTEM/OTNM → Co-share 患者确认 → 进入表单；随后 **Admission Request (1.5.1)** Create Case |
| **STEP 5** 等 GL 结果（App 收通知） | **QMS (1.13)** 派单 → **Manual Assessment**：审核员核 PAF 内容 → Update Diagnosis & Procedures → System matched **ICD/LOS/Value** → 需补材料走 **Deferment (1.12)** → Approve → **Generate Approved GL + Log Number** → G400/MCS 建 Claim Record → **通知引擎 (1.29)** 推送 Approved/Declined |
| **STEP 6** 住院治疗中追加项目/额度 | **Additional GL Request (1.5.2)**（新增诊断/操作，可部分批，拒条目可 Appeal）；**Top-Up Request (1.5.3)**（额度不够） |
| **STEP 7** 出院结算 | **Discharge Request (1.5.4)**：可补医生/诊断 → 金额存疑触发 **AUC (1.15)** 澄清 → **Amended Bill (1.5.5)** 按审核意见修正 → **Final Bill Submission (1.5.6)**（金额=批准额；7 天不提自动创建）→ **FGL** + Claim Status update to CA (G400)；出院后复诊走 **Follow-Up GL / Bill (1.5.7/1.5.8)** |

**EB 旅程要点**：多一道 **e-Referral 转诊前置**；住院靠 **PAF 预授权**；病人全程只跟"诊所→医院→App"打交道，Portal/CRM/后端的全部动作对病人不可见。

---

## 2. IB 个人福利（个人险）就医全旅程 / IB Patient Journey

> 人物设定：个人客户 Contact（本人投保）。

### 前台旅程（病人视角，5 步）

```
STEP 1  自己找定点医院 (Find a Panel Hospital) ── 查营业时间/服务/折扣
STEP 2  出示电子医疗卡 (Present Medical eCard) ── 医院代办 IGL 申请手续
STEP 3  入院前在手机 App 查 GL 结果 (Check GL Decision via App)
        └── 拿到 GL 才能免现金 (Cashless) 入院
STEP 4  交医院押金 (Pay Hospital Deposit)
        └── 有 GL 押金可降低；Platinum Hospital 免押金
STEP 5  出院 (Discharge) ── 医院提交账单与出院文件 → FGL
        └── 有共保/免赔的，与保险公司分担费用
```

### 前台 × 后台对照表

| 病人看到的（Front-stage） | 系统里发生的（Back-stage 对应流程） |
|---|---|
| **STEP 1** 自己选定点医院 | 医院主数据来自 **Hospital Master (1.25)**（OneData 校验；IB 医院带 Vendor/Address Code）；"是否定点"即 IB 患者搜索里的 **Within PHN / Cashless Facilities** 判断 |
| **STEP 2** 前台出示 eCard，医院代办 | **Portal Patient Search – IB (1.2.2)**：Policy active → Active plan code → Cashless facilities → Within PHN → 显示保单详情；随后 **IB Request Submission (1.3.3)**：Waiting Period(仅意外) → **Premium Paid Date > 30 天 → Cash Value 现金价值是否够抵扣欠缴保费** → Utilization Balance → Co-share/Deductible 患者确认 → **Admission Request** 建案 |
| **STEP 3** App 查 GL 结果 | CRM 审核链（QMS → Assessment → Approve/Decline）完成后，**通知引擎 (1.29)** IB 分支按 **Role: Self/Others** 用 NRIC 检索 → 触发 **PN API** 推送到客户 App |
| **STEP 4** 交押金 | **系统外环节 (Outside System)**——押金是医院与病人之间的行为，CRM 不管理；GL 的存在间接降低押金要求 |
| **STEP 5** 出院与费用分担 | **Discharge → Amended Bill → Final Bill** 同一骨架；EB/IB 分叉点：IB 的 Final Bill **直接更新 CRM 关联记录为 Completed**（不走 G400 CA 状态）；Follow-Up Bill 走 **QMS 人工审核**而非自动建理赔头；共保/免赔即建案时确认过的 Co-share/Deductible，落在 FGL 除外与病人自付上 |

**IB 旅程要点**：**没有转诊前置**，病人自主选医院；系统最关心的是**保单缴费状态**（保费超 30 天未缴 → 查现金价值）；App 自查 GL 是入院闸门。

---

## 3. 入院的三种方式 × 系统分支 / Three Admission Modes

| 入院方式 | 现实定义 | 系统对应 |
|---|---|---|
| Planned Admission (计划入院) | 专科医生建议住院 → 医院取信息与同意书 → 医生填 PAF → 预授权 → IGL → 入院当天无障碍 | 标准 **Admission Request** 主线（1.5.1） |
| Emergency Admission (急诊入院) | 突发状况直接入院 | 校验链中的 **Emergency Case? (急诊)** 分支——可越过 PHN 限制，走 OTEM 医院承担风险确认 |
| Daycare Procedure (日间手术) | 当日出入院，或住院 ≥6h 且 <24h 的预约手术；须医学必要+合格医生转介 | EB 旅程 STEP 4 中 "panel hospital will send **Daycare GL request**"——同走 IGL with PAF 预授权链 |

---

## 4. 出院结算通用剧本 / Discharge Playbook (EB & IB 共用)

```
前台 (病人/医院)                          后台 (系统)
─────────────────                        ─────────────────
1. 医生准备出院文件                        Discharge Request 建案 → QMS → 审核
   (Discharge Documents)                  ├─ Diagnosis/Procedures Changes? 更新
                                          ├─ Charges Information Valid? 费用校验
2. 医院整理账单+出院文件                    └─ AUC Required? → AUC 澄清流程 (1.15)
   提交保险公司                            Generate Draft GL → Amount Matched?
                                          ├─ 否 → Amended Bill 修正账单循环
3. 保险公司评估应付款                       └─ 是 → Update Final Details → Final GL
   作出理赔决定 → 签发 FGL                  Final Bill Submission (7 天窗口)
                                          → FGL + 后端理赔落账 (EB: G400 CA)
4. 病人付自付部分，出院回家                  Non-payable / Co-share / Deductible
   (Non-payable 医院当场收取)               = FGL Exclusion 除外项，病人自付
```

---

## 5. EB vs IB 病人体验差异速览 / Experience Differences at a Glance

| 维度 | EB 团体险病人 | IB 个人险病人 |
|---|---|---|
| 就医入口 | 先去**定点诊所拿 e-Referral**（30 天有效） | **自己直接找定点医院** |
| 住院前置 | 专科医生填 **PAF 预授权表** | 医院前台**代办**全部手续 |
| 最担心被卡的点 | 医院是否网络内（PHN/OTEM/OTNM） | 保费是否断缴（现金价值抵扣） |
| GL 获取方式 | App 收转诊 GL + 入院 IGL 通知 | 入院前 App **自查** GL 结果 |
| 押金 | （材料未强调） | 明确提示：GL 降押金，白金医院免押金 |
| 费用分担 | Non-payable 项目医院向成员收取 | Co-insurance/Co-takaful/Deductible 与保险公司分担 |
| 出院后 | Follow-Up 复诊仍走 GL 体系 | 同左，但账单走人工审核链 |

---

## 6. 一张图记住"前台 5 幕 × 后台 30 流程" / One Mental Map

```
病人视角 5 幕剧                后台流程群
─────────────                ─────────────────────────────
第1幕 找医院/拿转诊      →     Hospital Master / E-Referral / 通知引擎
第2幕 前台登记          →     Patient Search (EB/IB 校验链)
第3幕 申请住院          →     Request Creation Rules + Admission Request
                              + QMS/STP + Deferment
第4幕 住院治疗          →     Additional GL / Top-Up
第5幕 出院结算          →     Discharge + AUC + Amended/Final Bill
                              → FGL + 理赔落账 + Follow-Up
（幕间意外）申诉/取消/重开 →   Appeal / Cancellation / Case Reopen
```

**核心洞察**：客户旅程材料证明了一件事——**病人只经历 5 个动作，系统却要跑 30 个流程来支撑**。病人手机上"叮"一声收到 GL 的背后，是 Portal 校验 → CRM 建案 → QMS 派单 → 审核员核 PAF → 后端落账 → 通知引擎按 NRIC 找人推送的完整链条。理解了这个"前台极简、后台复杂"的映射，就真正打通了业务与系统。
