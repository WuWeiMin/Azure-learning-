# Dynamics 365 Developer Cheat Sheet

> A practical reference for Dynamics 365, Azure and Enterprise Software
> Development.

------------------------------------------------------------------------

# 1. Software Development

## BRD

**Full Name**

Business Requirement Document

**中文**

业务需求文档

**作用**

描述业务需求，是整个项目的起点。

**编写者**

Business Analyst (BA)

**相关**

FSD、TSD

------------------------------------------------------------------------

## FSD

**Full Name**

Functional Specification Document

**中文**

功能规格说明书

**作用**

详细描述系统需要实现的业务功能，是开发和测试最重要的依据。

**主要内容**

-   UI Design
-   Business Rules
-   Validation
-   Field Mapping
-   Integration
-   Error Messages

**编写者**

Business Analyst

**相关**

BRD、TSD、UAT

------------------------------------------------------------------------

## TSD

**Full Name**

Technical Specification Document

**中文**

技术设计文档

**作用**

说明开发如何实现 FSD，包括数据库、接口、插件、流程等技术设计。

**编写者**

Solution Architect / Tech Lead

------------------------------------------------------------------------

## Requirement Flow

``` text
Business Requirement
        │
        ▼
      BRD
        │
        ▼
      FSD
        │
        ▼
      TSD
        │
        ▼
   Development
        │
        ▼
     SIT / UAT
```

------------------------------------------------------------------------

# 2. Agile

  Term         Description
  ------------ ----------------
  Agile        敏捷开发
  Scrum        Scrum 开发框架
  Sprint       冲刺周期
  Epic         大功能
  Feature      功能
  User Story   用户故事
  Task         开发任务
  Bug          缺陷
  Spike        技术预研
  Backlog      待办列表

------------------------------------------------------------------------

# 3. Project Roles

  Acronym   Meaning
  --------- -----------------------
  PM        Project Manager
  BA        Business Analyst
  PO        Product Owner
  QA        Quality Assurance
  DEV       Developer
  SA        Solution Architect
  TL        Team Lead
  SME       Subject Matter Expert

------------------------------------------------------------------------

# 4. Dynamics 365

## Queue

**作用**

用于存放等待处理的工作项（Case、Email、Task 等）。

**Dataverse Table**

`queue`

**典型流程**

``` text
Case
  │
  ▼
Queue
  │
  ▼
BO Pick
  │
  ▼
MO Process
  │
  ▼
Completed
```

**项目经验**

-   Queue 表示待处理工作，不是权限控制。
-   推荐按业务阶段划分 Queue。

------------------------------------------------------------------------

## Queue Item

**Dataverse Table**

`queueitem`

**作用**

Queue 中的一条工作记录。

``` text
Queue
 ├── Queue Item -> Case
 ├── Queue Item -> Email
 └── Queue Item -> Task
```

**注意**

Queue Item ≠ User。

------------------------------------------------------------------------

## Business Rule (BR)

无需代码即可实现简单业务逻辑。

------------------------------------------------------------------------

## Business Process Flow (BPF)

引导用户按业务阶段完成流程。

------------------------------------------------------------------------

## Plugin

服务器端业务逻辑。

适用于：

-   数据验证
-   自动计算
-   集成
-   同步/异步业务处理

------------------------------------------------------------------------

## Solution

用于迁移配置和代码。

-   Managed
-   Unmanaged

------------------------------------------------------------------------

## Dataverse

Dynamics 365 的数据平台。

------------------------------------------------------------------------

# 5. Azure

  Service          Description
  ---------------- --------------------
  Azure Function   无服务器计算
  Service Bus      消息队列
  APIM             API Management
  ADF              Azure Data Factory
  Logic App        工作流

------------------------------------------------------------------------

# 6. Integration

  Acronym   Meaning
  --------- ------------------
  REST      REST API
  SOAP      SOAP Web Service
  OAuth     授权协议
  JWT       Token
  JSON      数据交换格式
  XML       XML 数据格式
  API       应用接口
  ETL       数据同步

------------------------------------------------------------------------

# 7. Database

  Acronym            Meaning
  ------------------ -----------------------------
  PK                 Primary Key
  FK                 Foreign Key
  ERD                Entity Relationship Diagram
  View               数据库视图
  Stored Procedure   存储过程
  Transaction        事务

------------------------------------------------------------------------

# 8. Medical Insurance Terms

  Term         Meaning
  ------------ -------------------------------------
  GL           Guarantee Letter
  IGL          Initial GL
  AGL          Amended GL
  FGL          Final GL
  PAF          Pre-Authorisation Form
  ePAF         Electronic PAF
  Claim        理赔
  HIS          Hospital Information System
  EDI          Electronic Data Interchange
  EIP          Enterprise Integration Platform
  GP           General Practitioner
  SP           Specialist
  BO           Business Officer
  MO           Medical Officer
  MRN          Medical Record Number
  NRIC         National Registration Identity Card
  AUC          Amount Under Clarification
  NPI          Non Payable Item
  Co-share     自付比例
  Deductible   免赔额

------------------------------------------------------------------------

# 9. Frequently Used Project Terms

  Acronym    Meaning
  ---------- ----------------------------------
  CR         Change Request
  OOTB       Out Of The Box
  KT         Knowledge Transfer
  RCA        Root Cause Analysis
  ETA        Estimated Time of Arrival
  ALM        Application Lifecycle Management
  Hotfix     紧急修复
  Rollback   回滚

------------------------------------------------------------------------

# 10. Development Checklist

-   Read BRD
-   Read FSD
-   Review TSD
-   Confirm Acceptance Criteria
-   Develop
-   Unit Test
-   SIT
-   UAT
-   Deploy
-   Production Support
