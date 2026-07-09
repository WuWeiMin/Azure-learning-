# Software Development Acronyms Handbook

> Enterprise Software / Dynamics 365 / .NET / Azure

## 1. Requirement Documents

  -----------------------------------------------------------------------
  Acronym                 Full Name               Description
  ----------------------- ----------------------- -----------------------
  BRD                     Business Requirement    Business requirement
                          Document                document

  FSD                     Functional              Functional
                          Specification Document  specification document

  TSD                     Technical Specification Technical design
                          Document                document

  SRS                     Software Requirement    Software requirements
                          Specification           

  FRD                     Functional Requirement  Functional requirements
                          Document                

  NFR                     Non-Functional          Performance, security,
                          Requirement             scalability

  UC                      Use Case                Business use case

  UAT                     User Acceptance Testing User acceptance testing
  -----------------------------------------------------------------------

### Requirement Flow

``` text
Business Requirement
    ↓
BRD
    ↓
FSD
    ↓
TSD
    ↓
Development
    ↓
Testing
```

## 2. Project Roles

-   PM --- Project Manager
-   BA --- Business Analyst
-   SA --- Solution Architect
-   TL --- Team Lead
-   SME --- Subject Matter Expert
-   PO --- Product Owner
-   QA --- Quality Assurance
-   DEV --- Developer

## 3. Development

-   CRUD
-   API
-   SDK
-   DTO
-   ORM
-   POC
-   MVP

## 4. Testing

-   UT
-   SIT
-   UAT
-   E2E
-   Regression Test
-   Smoke Test
-   FAT
-   PAT

## 5. DevOps

-   CI
-   CD
-   IaC
-   Docker
-   Kubernetes (K8S)
-   YAML

## 6. Database

-   PK
-   FK
-   ERD
-   SP
-   ETL
-   CDC

## 7. API

-   REST
-   SOAP
-   JSON
-   XML
-   JWT
-   OAuth

## 8. Dynamics 365

-   CE
-   CS
-   FO
-   Dataverse
-   PCF
-   Plugin
-   Business Rule (BR)
-   Business Process Flow (BPF)
-   Workflow
-   Action
-   Queue
-   Queue Item
-   ALM
-   Managed / Unmanaged Solution

## 9. Queue

Queue = Work Pool

Dataverse table:

`queue`

Queue Item = One work item stored in a Queue.

Dataverse table:

`queueitem`

Relationship:

``` text
Queue
 ├── QueueItem -> Case
 ├── QueueItem -> Email
 ├── QueueItem -> Task
 └── QueueItem -> Custom Table
```

## 10. Common Project Terms

-   CR
-   RFC
-   RCA
-   ETA
-   KT
-   OOTB
-   Hotfix
-   Rollback
-   Spike
-   PBI

## 11. Development Lifecycle

``` text
BRD
 ↓
FSD
 ↓
TSD
 ↓
Plugin / JS / Web API
 ↓
Unit Test
 ↓
SIT
 ↓
UAT
 ↓
Production
```

## 12. Recommended to Master

-   BRD
-   FSD
-   TSD
-   OOTB
-   Plugin
-   Queue
-   Queue Item
-   API
-   UAT
-   SIT
-   ALM
-   Dataverse
-   BPF
-   Business Rule
-   Power Automate
-   Azure DevOps
