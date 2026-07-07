# Dynamics 365 Online Ribbon 按钮显示权限控制设计文档

## 1. 目标

本任务的目标是在 Dynamics 365 Online / Dataverse 中实现一个可配置的 Ribbon 按钮显示控制方案。

通过配置表控制某个 Ribbon Button 是否对当前用户显示。

支持以下权限类型：

- 指定用户 User
- 指定安全角色 Role
- 指定团队 Team
- 指定业务部门 Business Unit

最终效果：

```text
当前用户打开页面
        ↓
Ribbon 按钮 Display Rule 调用 JavaScript
        ↓
JavaScript 调用 Custom API
        ↓
Custom API 查询配置表并判断权限
        ↓
返回 true / false
        ↓
控制按钮显示或隐藏
```

---

## 2. 总体设计

我们创建两张自定义表：

```text
new_ribbon
new_ribbonrule
```

### 表一：new_ribbon

用于定义系统中需要控制的 Ribbon 按钮。

### 表二：new_ribbonrule

用于配置哪些用户、角色、团队或业务部门可以看到某个 Ribbon 按钮。

---

## 3. 表结构设计

## 3.1 new_ribbon 表

### 表用途

`new_ribbon` 用来保存 Ribbon 按钮的基础信息。

例如：

```text
Approve Button
Reject Button
Submit Button
Export Button
```

### 字段设计

| Display Name | Schema Name | Type | Required | 说明 |
|---|---|---|---|---|
| Name | new_name | Single Line of Text | Yes | 按钮名称 |
| Code | new_code | Single Line of Text | Yes | 按钮唯一编号 |
| Description | new_description | Multiple Lines of Text | No | 按钮说明 |

### 示例数据

| Name | Code | Description |
|---|---|---|
| Approve Button | BTN_APPROVE | 审批按钮 |
| Reject Button | BTN_REJECT | 拒绝按钮 |
| Submit Button | BTN_SUBMIT | 提交按钮 |

### 重要说明

不单独创建 `new_enable` 字段。

原因是 Dataverse 表已经自带系统状态字段：

```text
StateCode: Active / Inactive
StatusCode: Status Reason
```

如果某个 Ribbon 配置不再使用，直接 Deactivate 这条记录即可。

Custom API 查询时只查询 Active 状态的记录。

---

## 3.2 new_ribbonrule 表

### 表用途

`new_ribbonrule` 用来保存 Ribbon 按钮的显示规则。

一条 Ribbon 可以有多条 Rule。

只要当前用户满足任意一条 Rule，就可以显示按钮。

### 字段设计

| Display Name | Schema Name | Type | Required | 说明 |
|---|---|---|---|---|
| Name | new_name | Single Line of Text | Yes | 规则名称 |
| Ribbon | new_ribbon_r1 | Lookup to new_ribbon | Yes | 关联 Ribbon 按钮 |
| Type | new_type | Choice | Yes | 权限类型 |
| User | systemuser_r1 | Lookup to User | No | 指定用户 |
| Team | team_r1 | Lookup to Team | No | 指定团队 |
| Business Unit | businessunit_r1 | Lookup to Business Unit | No | 指定业务部门 |
| Role Name | new_rolename | Single Line of Text | No | 指定安全角色名称 |
| Description | new_description | Multiple Lines of Text | No | 规则说明 |

---

## 4. new_type Choice 设计

`new_type` 是 Choice 字段，用来区分当前规则类型。

建议选项如下：

| Label | Value | 说明 |
|---|---:|---|
| User | 100000000 | 按指定用户控制 |
| Role | 100000001 | 按安全角色名称控制 |
| Team | 100000002 | 按团队控制 |
| Business Unit | 100000003 | 按业务部门控制 |

---

## 5. 为什么 Role 不使用 Lookup

Role 不建议使用 Lookup。

原因是 Dynamics 365 中同一个安全角色名称可能会在不同 Business Unit 下生成多条 Role 记录。

例如：

```text
Sales Manager - Root Business Unit
Sales Manager - Canada Business Unit
Sales Manager - Calgary Business Unit
```

如果配置人员使用 Role Lookup，可能不知道应该选择哪一条。

所以 Role 使用文本字段：

```text
new_rolename
```

API 判断时读取当前用户拥有的所有角色名称，只要名称匹配即可。

---

## 6. 为什么 Team 可以使用 Lookup

Team 一般不会像 Role 一样因为 Business Unit 自动复制出大量同名记录。

Team 通常是业务上明确创建的团队，例如：

```text
Finance Approval Team
Sales Team
CSR Manager Team
```

所以 Team 使用 Lookup 更准确。

字段为：

```text
team_r1
```

API 判断时读取当前用户所属 Team 的 TeamId，然后和配置表中的 `team_r1` 比较。

---

## 7. 命名规则

关系字段使用：

```text
实体名 + _r1
```

当前设计如下：

```text
new_ribbon_r1
systemuser_r1
team_r1
businessunit_r1
```

这样命名的好处是：

- 一眼能看出 Lookup 指向哪个实体
- 后续如果有第二个同实体关系，可以继续使用 `_r2`
- 命名风格统一，便于维护

---

## 8. Custom API 设计

### API 名称

```text
new_CheckRibbonAccess
```

### API 类型

建议创建为 Custom API。

### Request 参数

| Name | Type | Required | 说明 |
|---|---|---|---|
| UserId | String | Yes | 当前用户 ID |
| RibbonCode | String | Yes | Ribbon 按钮编号 |

### Response 参数

| Name | Type | 说明 |
|---|---|---|
| HasAccess | Boolean | true 显示按钮，false 隐藏按钮 |

---

## 9. Custom API 判断逻辑

伪代码如下：

```text
Input:
  UserId
  RibbonCode

Step 1:
  根据 RibbonCode 查询 Active 状态的 new_ribbon

Step 2:
  如果没有找到 Ribbon，返回 false

Step 3:
  查询该 Ribbon 下所有 Active 状态的 new_ribbonrule

Step 4:
  如果没有任何 Rule，返回 false

Step 5:
  遍历 Rule

  如果 Type = User:
      判断 systemuser_r1 是否等于当前 UserId

  如果 Type = Role:
      查询当前用户所有 Role Name
      判断是否包含 new_rolename

  如果 Type = Team:
      查询当前用户所属 Team
      判断是否包含 team_r1

  如果 Type = Business Unit:
      查询当前用户的 Business Unit
      判断是否等于 businessunit_r1

Step 6:
  任意一条规则匹配成功，返回 true

Step 7:
  全部不匹配，返回 false
```

---

## 10. JavaScript Web Resource 设计

### Web Resource 名称建议

```text
new_/js/ribbonAccess.js
```

### 方法名称建议

```javascript
RibbonAccess.checkAccess
```

### JS 逻辑

```text
1. 获取当前用户 ID
2. 传入 Ribbon Code
3. 调用 Custom API: new_CheckRibbonAccess
4. 读取返回值 HasAccess
5. 返回 true / false 给 Ribbon Display Rule
```

### 示例结构

```javascript
var RibbonAccess = RibbonAccess || {};

RibbonAccess.checkAccess = function (ribbonCode) {
    var userId = Xrm.Utility.getGlobalContext().userSettings.userId;
    userId = userId.replace("{", "").replace("}", "");

    var request = {
        UserId: userId,
        RibbonCode: ribbonCode,
        getMetadata: function () {
            return {
                boundParameter: null,
                parameterTypes: {
                    "UserId": {
                        typeName: "Edm.String",
                        structuralProperty: 1
                    },
                    "RibbonCode": {
                        typeName: "Edm.String",
                        structuralProperty: 1
                    }
                },
                operationType: 0,
                operationName: "new_CheckRibbonAccess"
            };
        }
    };

    return Xrm.WebApi.online.execute(request).then(
        function success(response) {
            if (response.ok) {
                return response.json().then(function (result) {
                    return result.HasAccess === true;
                });
            }
            return false;
        },
        function error(e) {
            console.log(e.message);
            return false;
        }
    );
};
```

---

## 11. Ribbon Workbench 配置思路

### Display Rule

创建一个 JavaScript Rule。

配置：

```text
Library: new_/js/ribbonAccess.js
Function Name: RibbonAccess.checkAccess
Parameter: BTN_APPROVE
```

### 注意

不同 Ribbon 工具对异步 Promise 支持情况可能不同。

如果当前工具或环境不支持异步 Display Rule，可以改成：

```text
页面加载时提前调用 API
把结果缓存到 window 变量
Ribbon Display Rule 只读取缓存值
```

第一版可以先按直接调用 Custom API 的方式尝试。

---

## 12. 配置示例

### 示例一：只有某个用户可以看到审批按钮

new_ribbon：

| Name | Code |
|---|---|
| Approve Button | BTN_APPROVE |

new_ribbonrule：

| Ribbon | Type | User |
|---|---|---|
| Approve Button | User | Zhang San |

结果：

```text
只有 Zhang San 可以看到 BTN_APPROVE 按钮
```

---

### 示例二：拥有 Sales Manager 角色的人可以看到按钮

new_ribbonrule：

| Ribbon | Type | Role Name |
|---|---|---|
| Approve Button | Role | Sales Manager |

结果：

```text
只要当前用户拥有 Sales Manager 角色，就可以看到按钮
```

---

### 示例三：Finance Approval Team 成员可以看到按钮

new_ribbonrule：

| Ribbon | Type | Team |
|---|---|---|
| Approve Button | Team | Finance Approval Team |

结果：

```text
只要当前用户属于 Finance Approval Team，就可以看到按钮
```

---

### 示例四：某个 Business Unit 下的用户可以看到按钮

new_ribbonrule：

| Ribbon | Type | Business Unit |
|---|---|---|
| Approve Button | Business Unit | Calgary Business Unit |

结果：

```text
当前用户所属业务部门是 Calgary Business Unit 时，可以看到按钮
```

---

## 13. 操作步骤

## Step 1：创建 new_ribbon 表

在 Power Apps Maker Portal 中：

```text
Solutions
  ↓
选择你的 Solution
  ↓
New
  ↓
Table
```

创建表：

```text
Display Name: Ribbon
Plural Name: Ribbons
Schema Name: new_ribbon
```

添加字段：

```text
new_code
new_description
```

`new_name` 系统主字段默认存在。

---

## Step 2：创建 new_ribbonrule 表

创建表：

```text
Display Name: Ribbon Rule
Plural Name: Ribbon Rules
Schema Name: new_ribbonrule
```

添加字段：

```text
new_ribbon_r1
new_type
systemuser_r1
team_r1
businessunit_r1
new_rolename
new_description
```

---

## Step 3：创建 Choice 字段 new_type

字段类型选择：

```text
Choice
```

添加选项：

```text
User
Role
Team
Business Unit
```

---

## Step 4：创建测试数据

先创建一条 Ribbon：

```text
Name: Approve Button
Code: BTN_APPROVE
Description: 审批按钮
```

再创建一条 Ribbon Rule：

```text
Ribbon: Approve Button
Type: User
User: 当前测试用户
```

---

## Step 5：创建 Custom API

创建 Custom API：

```text
Name: new_CheckRibbonAccess
```

添加 Request 参数：

```text
UserId: String
RibbonCode: String
```

添加 Response 参数：

```text
HasAccess: Boolean
```

---

## Step 6：开发 Plugin

Plugin 绑定到 Custom API。

Plugin 中实现：

```text
查询 new_ribbon
查询 new_ribbonrule
判断 User / Role / Team / Business Unit
返回 HasAccess
```

---

## Step 7：创建 JavaScript Web Resource

创建 Web Resource：

```text
new_/js/ribbonAccess.js
```

写入调用 Custom API 的 JS 方法。

---

## Step 8：配置 Ribbon Button Display Rule

在 Ribbon Workbench 中：

```text
给目标 Button 添加 Display Rule
Display Rule 类型选择 JavaScript Rule
Library 选择 new_/js/ribbonAccess.js
Function 填 RibbonAccess.checkAccess
Parameter 填 BTN_APPROVE
```

---

## Step 9：测试

测试四种情况：

```text
1. 当前用户被直接配置为 User → 应显示
2. 当前用户拥有配置的 Role → 应显示
3. 当前用户属于配置的 Team → 应显示
4. 当前用户属于配置的 Business Unit → 应显示
5. 当前用户不满足任何规则 → 应隐藏
```

---

## 14. 第一版范围

第一版支持：

```text
User
Role
Team
Business Unit
```

暂不支持：

```text
Manager
Position
Field Security Profile
AAD Group 直接判断
复杂 AND / OR 条件
排除规则 Deny Rule
```

后续如果需要，可以扩展 `new_type` 或增加规则模式字段。

---

## 15. 当前最终表设计

### new_ribbon

```text
new_name
new_code
new_description
statecode
statuscode
```

### new_ribbonrule

```text
new_name
new_ribbon_r1
new_type
systemuser_r1
team_r1
businessunit_r1
new_rolename
new_description
statecode
statuscode
```

---

## 16. 当前最终逻辑

```text
Ribbon Code 是按钮唯一标识
Rule 是按钮显示权限配置
当前用户满足任意一条 Active Rule 即可显示按钮
Role 使用名称匹配
User / Team / Business Unit 使用 Lookup 匹配
Active / Inactive 使用系统状态控制
```


---

## 17. Web API 调用代码补充

这一部分补充前端 JavaScript Web Resource 中调用 Custom API 的完整代码。

> 说明：Ribbon Display Rule 中调用异步 Web API 时，部分环境可能不稳定。建议第一版先测试 Promise 方式；如果 Ribbon Workbench 不接受异步返回，再改成页面加载时预缓存权限结果。

---

## 17.1 推荐版：直接调用 Custom API

Web Resource 名称：

```text
new_/js/ribbonAccess.js
```

完整代码：

```javascript
var RibbonAccess = RibbonAccess || {};

(function () {
    /**
     * Ribbon Display Rule 调用入口
     * @param {string} ribbonCode 按钮编号，例如 BTN_APPROVE
     * @returns {Promise<boolean>} true 显示按钮，false 隐藏按钮
     */
    RibbonAccess.checkAccess = function (ribbonCode) {
        try {
            var globalContext = Xrm.Utility.getGlobalContext();
            var userId = globalContext.userSettings.userId;

            if (!userId || !ribbonCode) {
                return Promise.resolve(false);
            }

            userId = userId.replace("{", "").replace("}", "");

            var request = {
                UserId: userId,
                RibbonCode: ribbonCode,

                getMetadata: function () {
                    return {
                        boundParameter: null,
                        parameterTypes: {
                            "UserId": {
                                typeName: "Edm.String",
                                structuralProperty: 1
                            },
                            "RibbonCode": {
                                typeName: "Edm.String",
                                structuralProperty: 1
                            }
                        },
                        operationType: 0,
                        operationName: "new_CheckRibbonAccess"
                    };
                }
            };

            return Xrm.WebApi.online.execute(request).then(
                function success(response) {
                    if (!response.ok) {
                        return false;
                    }

                    return response.json().then(function (result) {
                        return result && result.HasAccess === true;
                    });
                },
                function error(error) {
                    console.error("RibbonAccess.checkAccess error:", error.message);
                    return false;
                }
            );
        } catch (e) {
            console.error("RibbonAccess.checkAccess exception:", e.message);
            return Promise.resolve(false);
        }
    };
})();
```

---

## 17.2 Ribbon Workbench 配置方式

Display Rule 使用 JavaScript Rule：

```text
Library: new_/js/ribbonAccess.js
Function Name: RibbonAccess.checkAccess
Parameter 1: BTN_APPROVE
```

如果你的按钮是审批按钮，则参数写：

```text
BTN_APPROVE
```

如果以后还有其他按钮，例如：

```text
BTN_REJECT
BTN_SUBMIT
BTN_EXPORT
```

只需要在不同按钮的 Display Rule 参数中传入不同的 Ribbon Code。

---

## 17.3 调试用代码

如果要在浏览器 Console 里测试，可以打开模型驱动应用页面后执行：

```javascript
RibbonAccess.checkAccess("BTN_APPROVE").then(function (result) {
    console.log("HasAccess:", result);
});
```

如果输出：

```text
HasAccess: true
```

说明当前用户有权限看到按钮。

如果输出：

```text
HasAccess: false
```

说明当前用户没有权限，或者 Custom API / Plugin 逻辑没有正确返回。

---

## 17.4 备用版：使用 XMLHttpRequest 调用 Custom API

如果 `Xrm.WebApi.online.execute` 在当前环境中不好调试，也可以先用 XMLHttpRequest 测试。

```javascript
var RibbonAccess = RibbonAccess || {};

(function () {
    RibbonAccess.checkAccessByXHR = function (ribbonCode) {
        return new Promise(function (resolve) {
            try {
                var globalContext = Xrm.Utility.getGlobalContext();
                var clientUrl = globalContext.getClientUrl();
                var userId = globalContext.userSettings.userId;

                if (!userId || !ribbonCode) {
                    resolve(false);
                    return;
                }

                userId = userId.replace("{", "").replace("}", "");

                var req = new XMLHttpRequest();
                req.open("POST", clientUrl + "/api/data/v9.2/new_CheckRibbonAccess", true);
                req.setRequestHeader("OData-MaxVersion", "4.0");
                req.setRequestHeader("OData-Version", "4.0");
                req.setRequestHeader("Accept", "application/json");
                req.setRequestHeader("Content-Type", "application/json; charset=utf-8");

                req.onreadystatechange = function () {
                    if (this.readyState === 4) {
                        req.onreadystatechange = null;

                        if (this.status === 200 || this.status === 204) {
                            var result = this.responseText ? JSON.parse(this.responseText) : null;
                            resolve(result && result.HasAccess === true);
                        } else {
                            console.error("Custom API call failed:", this.status, this.responseText);
                            resolve(false);
                        }
                    }
                };

                var body = {
                    UserId: userId,
                    RibbonCode: ribbonCode
                };

                req.send(JSON.stringify(body));
            } catch (e) {
                console.error("RibbonAccess.checkAccessByXHR exception:", e.message);
                resolve(false);
            }
        });
    };
})();
```

测试：

```javascript
RibbonAccess.checkAccessByXHR("BTN_APPROVE").then(console.log);
```

---

## 18. Custom API Plugin C# 代码参考

下面是 Plugin 的核心代码参考。实际项目中需要根据你的命名空间、项目结构和 SDK 包版本调整。

### 18.1 Plugin 类代码

```csharp
using System;
using System.Linq;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;

namespace D365.RibbonAccess.Plugins
{
    public class CheckRibbonAccessPlugin : IPlugin
    {
        private const int TypeUser = 100000000;
        private const int TypeRole = 100000001;
        private const int TypeTeam = 100000002;
        private const int TypeBusinessUnit = 100000003;

        public void Execute(IServiceProvider serviceProvider)
        {
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            var serviceFactory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            var service = serviceFactory.CreateOrganizationService(context.UserId);
            var tracing = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            bool hasAccess = false;

            try
            {
                string userIdText = context.InputParameters.Contains("UserId")
                    ? context.InputParameters["UserId"] as string
                    : null;

                string ribbonCode = context.InputParameters.Contains("RibbonCode")
                    ? context.InputParameters["RibbonCode"] as string
                    : null;

                if (string.IsNullOrWhiteSpace(userIdText) || string.IsNullOrWhiteSpace(ribbonCode))
                {
                    context.OutputParameters["HasAccess"] = false;
                    return;
                }

                Guid userId = Guid.Parse(userIdText);

                Entity ribbon = GetActiveRibbonByCode(service, ribbonCode);
                if (ribbon == null)
                {
                    context.OutputParameters["HasAccess"] = false;
                    return;
                }

                EntityCollection rules = GetActiveRibbonRules(service, ribbon.Id);
                if (rules.Entities.Count == 0)
                {
                    context.OutputParameters["HasAccess"] = false;
                    return;
                }

                Entity user = service.Retrieve(
                    "systemuser",
                    userId,
                    new ColumnSet("businessunitid")
                );

                Guid? userBusinessUnitId = user.GetAttributeValue<EntityReference>("businessunitid")?.Id;

                var userRoleNames = GetUserRoleNames(service, userId);
                var userTeamIds = GetUserTeamIds(service, userId);

                foreach (var rule in rules.Entities)
                {
                    var typeOption = rule.GetAttributeValue<OptionSetValue>("new_type");
                    if (typeOption == null)
                    {
                        continue;
                    }

                    int type = typeOption.Value;

                    if (type == TypeUser)
                    {
                        var ruleUser = rule.GetAttributeValue<EntityReference>("systemuser_r1");
                        if (ruleUser != null && ruleUser.Id == userId)
                        {
                            hasAccess = true;
                            break;
                        }
                    }
                    else if (type == TypeRole)
                    {
                        string roleName = rule.GetAttributeValue<string>("new_rolename");
                        if (!string.IsNullOrWhiteSpace(roleName)
                            && userRoleNames.Any(r => string.Equals(r, roleName, StringComparison.OrdinalIgnoreCase)))
                        {
                            hasAccess = true;
                            break;
                        }
                    }
                    else if (type == TypeTeam)
                    {
                        var ruleTeam = rule.GetAttributeValue<EntityReference>("team_r1");
                        if (ruleTeam != null && userTeamIds.Contains(ruleTeam.Id))
                        {
                            hasAccess = true;
                            break;
                        }
                    }
                    else if (type == TypeBusinessUnit)
                    {
                        var ruleBusinessUnit = rule.GetAttributeValue<EntityReference>("businessunit_r1");
                        if (ruleBusinessUnit != null && userBusinessUnitId.HasValue && ruleBusinessUnit.Id == userBusinessUnitId.Value)
                        {
                            hasAccess = true;
                            break;
                        }
                    }
                }

                context.OutputParameters["HasAccess"] = hasAccess;
            }
            catch (Exception ex)
            {
                tracing.Trace("CheckRibbonAccessPlugin error: {0}", ex.ToString());
                context.OutputParameters["HasAccess"] = false;
            }
        }

        private Entity GetActiveRibbonByCode(IOrganizationService service, string ribbonCode)
        {
            var query = new QueryExpression("new_ribbon")
            {
                ColumnSet = new ColumnSet("new_ribbonid", "new_name", "new_code"),
                TopCount = 1
            };

            query.Criteria.AddCondition("statecode", ConditionOperator.Equal, 0);
            query.Criteria.AddCondition("new_code", ConditionOperator.Equal, ribbonCode);

            var result = service.RetrieveMultiple(query);
            return result.Entities.FirstOrDefault();
        }

        private EntityCollection GetActiveRibbonRules(IOrganizationService service, Guid ribbonId)
        {
            var query = new QueryExpression("new_ribbonrule")
            {
                ColumnSet = new ColumnSet(
                    "new_ribbonruleid",
                    "new_name",
                    "new_type",
                    "systemuser_r1",
                    "team_r1",
                    "businessunit_r1",
                    "new_rolename"
                )
            };

            query.Criteria.AddCondition("statecode", ConditionOperator.Equal, 0);
            query.Criteria.AddCondition("new_ribbon_r1", ConditionOperator.Equal, ribbonId);

            return service.RetrieveMultiple(query);
        }

        private string[] GetUserRoleNames(IOrganizationService service, Guid userId)
        {
            var query = new QueryExpression("role")
            {
                ColumnSet = new ColumnSet("name")
            };

            var link = query.AddLink("systemuserroles", "roleid", "roleid");
            link.LinkCriteria.AddCondition("systemuserid", ConditionOperator.Equal, userId);

            var roles = service.RetrieveMultiple(query);

            return roles.Entities
                .Select(r => r.GetAttributeValue<string>("name"))
                .Where(n => !string.IsNullOrWhiteSpace(n))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray();
        }

        private Guid[] GetUserTeamIds(IOrganizationService service, Guid userId)
        {
            var query = new QueryExpression("team")
            {
                ColumnSet = new ColumnSet("teamid")
            };

            var link = query.AddLink("teammembership", "teamid", "teamid");
            link.LinkCriteria.AddCondition("systemuserid", ConditionOperator.Equal, userId);

            var teams = service.RetrieveMultiple(query);

            return teams.Entities
                .Select(t => t.Id)
                .Distinct()
                .ToArray();
        }
    }
}
```

---

## 18.2 Plugin 注册说明

Plugin 注册到 Custom API：

```text
Message: new_CheckRibbonAccess
Stage: Main Operation
Mode: Synchronous
```

Custom API 设置建议：

```text
Unique Name: new_CheckRibbonAccess
Binding Type: Global
Is Function: No
Allowed Custom Processing Step Type: Sync and Async 或 Sync Only
Execute Privilege Name: 留空，或按需要设置
```

Request Parameters：

```text
UserId      String
RibbonCode  String
```

Response Property：

```text
HasAccess   Boolean
```

---

## 18.3 重要字段名称检查

代码中使用的字段必须和实际 Schema Name 一致：

```text
new_ribbon
new_ribbonrule
new_code
new_ribbon_r1
new_type
systemuser_r1
team_r1
businessunit_r1
new_rolename
```

如果你创建 Lookup 字段时系统自动生成了不同的 Schema Name，需要把 C# 和 JavaScript 中的字段名同步改掉。

---

## 19. 推荐先测试的最小闭环

建议先只测试 User 类型规则：

```text
1. 创建 new_ribbon: BTN_APPROVE
2. 创建 new_ribbonrule:
   Type = User
   User = 当前登录用户
3. 注册 Custom API 和 Plugin
4. 在 Console 执行：
   RibbonAccess.checkAccess("BTN_APPROVE").then(console.log)
5. 确认返回 true
6. 把 User 改成其他用户
7. 再测试应返回 false
```

User 类型跑通后，再测试 Role、Team、Business Unit。
