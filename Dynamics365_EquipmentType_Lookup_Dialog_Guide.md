# Dynamics 365：Equipment Type Lookup 弹窗功能复现指南

## 1. 目标

在 `Equipment Repair Request` 表单中增加一个命令栏按钮：

```text
Select Equipment Type
```

用户点击按钮后：

1. 打开一个自定义弹窗。
2. 弹窗中显示 `Equipment Type` 输入框和放大镜按钮。
3. 点击放大镜后打开 Dynamics 365 原生 `Lookup Records` 窗口。
4. 用户从 `EquipmentType` 表中选择一条记录。
5. 所选记录名称返回并显示在弹窗中。
6. 点击 `OK` 后，将所选 Equipment Type 写入当前 `Equipment Repair Request` 记录。
7. 关闭弹窗并刷新主表单。

---

## 2. 当前数据结构

### 2.1 Equipment Repair Request 表

| 项目 | 值 |
|---|---|
| Display Name | Equipment Repair Request |
| Logical Name | `demo_equipmentrepairrequest` |
| Entity Set Name | `demo_equipmentrepairrequests` |
| Primary ID | `demo_equipmentrepairrequestid` |
| Equipment Type Lookup Column | `demo_equipmenttype_r1` |

### 2.2 EquipmentType 表

| 项目 | 值 |
|---|---|
| Display Name | EquipmentType |
| Logical Name | `demo_equipmenttype` |
| Entity Set Name | `demo_equipmenttypes` |
| Primary ID | `demo_equipmenttypeid` |
| Primary Name Column | `demo_name` |

> 注意：Maker 页面可能显示 `demo_Name`，但在 Web API 和 JavaScript 中通常使用逻辑名称 `demo_name`。

---

## 3. 功能架构

```text
Equipment Repair Request 主表单
        ↓
Command Bar Button
        ↓
JavaScript：打开 Dialog
        ↓
HTML Web Resource
        ↓
Xrm.Utility.lookupObjects()
        ↓
Dynamics 原生 Lookup Records
        ↓
选择 EquipmentType
        ↓
Xrm.WebApi.updateRecord()
        ↓
更新 demo_equipmenttype_r1
        ↓
关闭弹窗
        ↓
刷新主表单
```

---

## 4. 需要创建的组件

在解决方案 `Equipment Repair Demo` 中创建以下组件：

| 类型 | 名称 |
|---|---|
| JavaScript Web Resource | `demo_/EquipmentRepair/equipmentRepairCommand.js` |
| HTML Web Resource | `demo_/EquipmentRepair/selectEquipmentType.html` |
| Command Bar Button | `Select Equipment Type` |

为了减少路径问题，本指南把弹窗逻辑直接写在 HTML 文件内部，不再额外创建第二个 JavaScript 文件。

---

# 5. 第一步：确认 Lookup 导航属性

虽然字段列表中显示 Lookup 列名称为：

```text
demo_equipmenttype_r1
```

但使用 `@odata.bind` 更新 Lookup 时，左侧必须使用真正的 Navigation Property Name。

在 XrmToolBox 的 Metadata Browser 中：

1. 选择表：

```text
demo_equipmentrepairrequest
```

2. 打开：

```text
Many-to-One Relationships
```

3. 找到目标表为：

```text
demo_equipmenttype
```

4. 记录以下值：

```text
ReferencingAttribute
ReferencingEntityNavigationPropertyName
ReferencedEntity
SchemaName
```

预期可能是：

```text
ReferencingAttribute:
demo_equipmenttype_r1

ReferencingEntityNavigationPropertyName:
demo_equipmenttype_r1
```

如果 `ReferencingEntityNavigationPropertyName` 不是 `demo_equipmenttype_r1`，则后面代码中的：

```javascript
demo_equipmenttype_r1@odata.bind
```

必须替换成真实的 Navigation Property Name。

---

# 6. 第二步：创建命令 JavaScript

在解决方案中选择：

```text
New
→ More
→ Web resource
```

填写：

```text
Name:
demo_/EquipmentRepair/equipmentRepairCommand.js

Display Name:
Equipment Repair Command

Type:
JavaScript
```

代码如下：

```javascript
var EquipmentRepairCommand = EquipmentRepairCommand || {};

EquipmentRepairCommand.openEquipmentTypeDialog = function (primaryControl) {
    "use strict";

    try {
        var formContext = primaryControl;

        if (!formContext || !formContext.data) {
            throw new Error(
                "Unable to access the Equipment Repair Request form."
            );
        }

        var requestId = formContext.data.entity.getId();

        if (!requestId) {
            Xrm.Navigation.openAlertDialog({
                title: "Select Equipment Type",
                text: "Please save the Equipment Repair Request first."
            });

            return;
        }

        requestId = requestId.replace(/[{}]/g, "");

        var pageInput = {
            pageType: "webresource",
            webresourceName:
                "demo_/EquipmentRepair/selectEquipmentType.html",
            data: JSON.stringify({
                requestId: requestId
            })
        };

        var navigationOptions = {
            target: 2,
            position: 1,
            width: {
                value: 520,
                unit: "px"
            },
            height: {
                value: 260,
                unit: "px"
            },
            title: "Select Equipment Type"
        };

        Xrm.Navigation.navigateTo(
            pageInput,
            navigationOptions
        ).then(
            function () {
                formContext.data.refresh(false);
                formContext.ui.refreshRibbon();
            },
            function (error) {
                console.error(
                    "Unable to open Equipment Type dialog.",
                    error
                );

                Xrm.Navigation.openErrorDialog({
                    message:
                        error.message ||
                        "Unable to open the Equipment Type dialog."
                });
            }
        );
    } catch (error) {
        console.error(error);

        Xrm.Navigation.openErrorDialog({
            message:
                error.message ||
                "An unexpected error occurred."
        });
    }
};
```

保存并发布该 Web Resource。

---

# 7. 第三步：创建 HTML Web Resource

在解决方案中创建：

```text
Name:
demo_/EquipmentRepair/selectEquipmentType.html

Display Name:
Select Equipment Type Dialog

Type:
Webpage (HTML)
```

完整代码如下：

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1"
    />

    <title>Select Equipment Type</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 24px;
            font-family: "Segoe UI", Arial, sans-serif;
            font-size: 14px;
            color: #323130;
            background-color: #ffffff;
        }

        .field-row {
            display: flex;
            align-items: center;
            margin-top: 18px;
        }

        .field-label {
            width: 145px;
            margin-right: 12px;
            font-weight: 600;
            text-align: right;
        }

        .lookup-container {
            display: flex;
            flex: 1;
            min-width: 0;
        }

        .lookup-input {
            flex: 1;
            height: 34px;
            min-width: 0;
            padding: 5px 8px;
            border: 1px solid #8a8886;
            font-family: inherit;
            font-size: 14px;
            background-color: #ffffff;
        }

        .lookup-button {
            width: 42px;
            height: 34px;
            margin-left: 4px;
            border: none;
            font-size: 21px;
            cursor: pointer;
            background-color: transparent;
        }

        .lookup-button:hover {
            background-color: #f3f2f1;
        }

        .message {
            min-height: 22px;
            margin-top: 12px;
            color: #a4262c;
            text-align: center;
        }

        .button-row {
            display: flex;
            justify-content: center;
            gap: 8px;
            margin-top: 14px;
        }

        .dialog-button {
            min-width: 82px;
            height: 36px;
            border: 1px solid #0f6cbd;
            font-family: inherit;
            font-size: 14px;
            cursor: pointer;
        }

        .primary-button {
            color: #ffffff;
            background-color: #0f6cbd;
        }

        .primary-button:hover {
            background-color: #115ea3;
        }

        .secondary-button {
            color: #323130;
            border-color: #8a8886;
            background-color: #ffffff;
        }

        .secondary-button:hover {
            background-color: #f3f2f1;
        }

        .dialog-button:disabled {
            color: #605e5c;
            border-color: #c8c6c4;
            cursor: default;
            background-color: #edebe9;
        }
    </style>
</head>

<body>
    <div class="field-row">
        <label
            class="field-label"
            for="equipmentTypeName">
            Equipment Type
        </label>

        <div class="lookup-container">
            <input
                id="equipmentTypeName"
                class="lookup-input"
                type="text"
                readonly
                aria-readonly="true"
            />

            <button
                id="lookupButton"
                class="lookup-button"
                type="button"
                title="Select Equipment Type"
                aria-label="Select Equipment Type">
                🔍
            </button>
        </div>
    </div>

    <div
        id="message"
        class="message"
        role="alert">
    </div>

    <div class="button-row">
        <button
            id="okButton"
            class="dialog-button primary-button"
            type="button">
            OK
        </button>

        <button
            id="cancelButton"
            class="dialog-button secondary-button"
            type="button">
            Cancel
        </button>
    </div>

    <script>
        var EquipmentTypeDialog = {
            requestId: null,
            selectedEquipmentType: null
        };

        EquipmentTypeDialog.getXrm = function () {
            if (window.parent && window.parent.Xrm) {
                return window.parent.Xrm;
            }

            if (window.Xrm) {
                return window.Xrm;
            }

            throw new Error(
                "Dynamics 365 Xrm context is unavailable."
            );
        };

        EquipmentTypeDialog.readParameters = function () {
            var query = new URLSearchParams(window.location.search);
            var rawData = query.get("data");

            if (!rawData) {
                throw new Error(
                    "The Equipment Repair Request ID was not supplied."
                );
            }

            var data;

            try {
                data = JSON.parse(decodeURIComponent(rawData));
            } catch (firstError) {
                data = JSON.parse(rawData);
            }

            if (!data.requestId) {
                throw new Error(
                    "The Equipment Repair Request ID is invalid."
                );
            }

            EquipmentTypeDialog.requestId =
                data.requestId.replace(/[{}]/g, "");
        };

        EquipmentTypeDialog.openLookup = function () {
            EquipmentTypeDialog.clearMessage();

            try {
                var xrm = EquipmentTypeDialog.getXrm();

                var lookupOptions = {
                    allowMultiSelect: false,
                    defaultEntityType: "demo_equipmenttype",
                    entityTypes: [
                        "demo_equipmenttype"
                    ],
                    disableMru: true
                };

                xrm.Utility.lookupObjects(lookupOptions).then(
                    function (results) {
                        if (!results || results.length === 0) {
                            return;
                        }

                        var selected = results[0];

                        EquipmentTypeDialog.selectedEquipmentType = {
                            id: selected.id.replace(/[{}]/g, ""),
                            name: selected.name || "",
                            entityType: selected.entityType
                        };

                        document
                            .getElementById("equipmentTypeName")
                            .value =
                                EquipmentTypeDialog
                                    .selectedEquipmentType
                                    .name;
                    },
                    function (error) {
                        console.error(
                            "Equipment Type lookup failed.",
                            error
                        );

                        EquipmentTypeDialog.showMessage(
                            error.message ||
                            "Unable to open the Equipment Type lookup."
                        );
                    }
                );
            } catch (error) {
                console.error(error);

                EquipmentTypeDialog.showMessage(
                    error.message ||
                    "Unable to open the Equipment Type lookup."
                );
            }
        };

        EquipmentTypeDialog.save = async function () {
            EquipmentTypeDialog.clearMessage();

            if (!EquipmentTypeDialog.selectedEquipmentType) {
                EquipmentTypeDialog.showMessage(
                    "Please select an Equipment Type."
                );
                return;
            }

            if (!EquipmentTypeDialog.requestId) {
                EquipmentTypeDialog.showMessage(
                    "The Equipment Repair Request ID is unavailable."
                );
                return;
            }

            var okButton = document.getElementById("okButton");

            try {
                okButton.disabled = true;
                okButton.textContent = "Saving...";

                var xrm = EquipmentTypeDialog.getXrm();

                var updateData = {};

                /*
                 * IMPORTANT:
                 * 如果 Metadata Browser 中确认的
                 * ReferencingEntityNavigationPropertyName
                 * 不是 demo_equipmenttype_r1，
                 * 请将下面名称替换成真实值。
                 */
                updateData[
                    "demo_equipmenttype_r1@odata.bind"
                ] =
                    "/demo_equipmenttypes(" +
                    EquipmentTypeDialog
                        .selectedEquipmentType
                        .id +
                    ")";

                await xrm.WebApi.updateRecord(
                    "demo_equipmentrepairrequest",
                    EquipmentTypeDialog.requestId,
                    updateData
                );

                EquipmentTypeDialog.closeDialog();
            } catch (error) {
                console.error(
                    "Unable to update Equipment Repair Request.",
                    error
                );

                EquipmentTypeDialog.showMessage(
                    error.message ||
                    "Unable to save the selected Equipment Type."
                );
            } finally {
                okButton.disabled = false;
                okButton.textContent = "OK";
            }
        };

        EquipmentTypeDialog.closeDialog = function () {
            try {
                var xrm = EquipmentTypeDialog.getXrm();

                if (
                    xrm.Navigation &&
                    typeof xrm.Navigation.navigateBack === "function"
                ) {
                    xrm.Navigation.navigateBack();
                    return;
                }
            } catch (error) {
                console.warn(
                    "navigateBack is unavailable.",
                    error
                );
            }

            window.close();
        };

        EquipmentTypeDialog.showMessage = function (message) {
            document.getElementById("message").textContent =
                message || "";
        };

        EquipmentTypeDialog.clearMessage = function () {
            document.getElementById("message").textContent = "";
        };

        EquipmentTypeDialog.initialize = function () {
            try {
                EquipmentTypeDialog.readParameters();

                document
                    .getElementById("lookupButton")
                    .addEventListener(
                        "click",
                        EquipmentTypeDialog.openLookup
                    );

                document
                    .getElementById("okButton")
                    .addEventListener(
                        "click",
                        EquipmentTypeDialog.save
                    );

                document
                    .getElementById("cancelButton")
                    .addEventListener(
                        "click",
                        EquipmentTypeDialog.closeDialog
                    );
            } catch (error) {
                console.error(error);
                EquipmentTypeDialog.showMessage(error.message);
            }
        };

        document.addEventListener(
            "DOMContentLoaded",
            EquipmentTypeDialog.initialize
        );
    </script>
</body>
</html>
```

保存并发布 HTML Web Resource。

---

# 8. 第四步：创建命令栏按钮

进入：

```text
make.powerapps.com
→ Apps
→ 选择你的 Model-driven App
→ Edit
```

选择：

```text
Equipment Repair Request
→ Main form
→ Edit command bar
```

必须选择：

```text
Main form
```

不要选择：

```text
Main grid
Subgrid
Associated view
```

创建按钮：

```text
Label:
Select Equipment Type

Tooltip:
Select an Equipment Type for this repair request
```

Action 配置：

```text
Run JavaScript
```

Library：

```text
demo_/EquipmentRepair/equipmentRepairCommand.js
```

Function：

```text
EquipmentRepairCommand.openEquipmentTypeDialog
```

Parameter：

```text
PrimaryControl
```

保存并发布应用。

---

# 9. 如果使用 Ribbon Workbench

如果现代 Command Designer 无法方便地传入 `PrimaryControl`，可以使用 Ribbon Workbench。

配置内容：

```text
Button Label:
Select Equipment Type

Command:
JavaScript Action

Library:
demo_/EquipmentRepair/equipmentRepairCommand.js

Function:
EquipmentRepairCommand.openEquipmentTypeDialog

Parameter:
PrimaryControl
```

按钮应添加到：

```text
Equipment Repair Request
→ Form Ribbon
```

---

# 10. 准备测试数据

进入 `EquipmentType` 表的数据页面，创建测试记录。

例如：

| Name | TypeName | EquipmentInfo |
|---|---|---|
| Laptop | Computer | Portable computer |
| Desktop | Computer | Office desktop |
| Printer | Office Device | Network printer |
| Monitor | Display | External monitor |
| Router | Network Device | Wireless router |

最重要的是填写：

```text
Name
```

因为 `demo_name` 是 EquipmentType 的 Primary Name Column，Lookup Records 默认显示这个字段。

---

# 11. 测试步骤

## 11.1 打开一条已保存的记录

打开：

```text
Equipment Repair Request
```

确保记录已经保存并且有 GUID。

## 11.2 点击命令栏按钮

点击：

```text
Select Equipment Type
```

预期弹出：

```text
Select Equipment Type

Equipment Type [               ] 🔍

               OK   Cancel
```

## 11.3 点击放大镜

预期打开 Dynamics 365 原生：

```text
Lookup Records
Select record
Look for EquipmentType
```

## 11.4 搜索或按 Enter

应显示 EquipmentType 记录。

## 11.5 选择一条记录

选择后，记录名称应回填到弹窗输入框。

## 11.6 点击 OK

预期结果：

1. 当前 `Equipment Repair Request` 被更新。
2. `demo_equipmenttype_r1` 保存所选 EquipmentType。
3. 弹窗关闭。
4. 主表单刷新。
5. 表单上的 EquipmentType Lookup 显示新值。

---

# 12. 常见错误及处理

## 12.1 点击按钮没有反应

检查：

```text
JavaScript Web Resource 是否发布
Function name 是否完全一致
是否传入 PrimaryControl
按钮是否添加在 Main form
```

正确函数名：

```javascript
EquipmentRepairCommand.openEquipmentTypeDialog
```

---

## 12.2 找不到 HTML Web Resource

错误通常类似：

```text
Web resource not found
```

检查：

```javascript
webresourceName:
"demo_/EquipmentRepair/selectEquipmentType.html"
```

必须与 Web Resource 的 Name 完全一致，包括：

- 大小写
- 下划线
- 斜杠
- 文件扩展名

---

## 12.3 Lookup 打不开

检查：

```javascript
defaultEntityType: "demo_equipmenttype"
entityTypes: ["demo_equipmenttype"]
```

这里必须使用表的 Logical Name，而不是：

```text
Display Name
Schema Name
Entity Set Name
```

正确值：

```text
demo_equipmenttype
```

---

## 12.4 Lookup 中没有记录

检查：

1. EquipmentType 表中是否存在记录。
2. 当前用户是否有 EquipmentType 表的 Read 权限。
3. EquipmentType 记录的 `Name` 是否有值。
4. Lookup View 是否包含这些记录。
5. 是否存在 Active 状态过滤条件。

---

## 12.5 点击 OK 出现 undeclared property 错误

例如：

```text
An undeclared property 'demo_equipmenttype_r1' was found
```

说明：

```text
demo_equipmenttype_r1
```

可能不是正确的 Navigation Property Name。

请在 Metadata Browser 中查找：

```text
ReferencingEntityNavigationPropertyName
```

然后替换：

```javascript
updateData[
    "demo_equipmenttype_r1@odata.bind"
]
```

例如真实名称若为：

```text
demo_EquipmentType_Relationship
```

则改为：

```javascript
updateData[
    "demo_EquipmentType_Relationship@odata.bind"
] =
    "/demo_equipmenttypes(" +
    EquipmentTypeDialog.selectedEquipmentType.id +
    ")";
```

---

## 12.6 403 或权限错误

确认当前用户对以下表具有权限：

### Equipment Repair Request

```text
Read
Write
Append
```

### EquipmentType

```text
Read
Append To
```

Lookup 关系更新通常需要：

```text
主表：Append
目标表：Append To
```

---

## 12.7 弹窗关闭后表单没有刷新

确认命令代码中包含：

```javascript
formContext.data.refresh(false);
formContext.ui.refreshRibbon();
```

这些代码位于：

```javascript
Xrm.Navigation.navigateTo(...).then(...)
```

弹窗关闭后才会执行。

---

# 13. 可选增强功能

功能跑通后可以继续增加以下内容。

## 13.1 打开弹窗时显示已有 Equipment Type

当前版本默认输入框为空。

可以在按钮 JS 中读取当前 Lookup：

```javascript
var currentLookup =
    formContext
        .getAttribute("demo_equipmenttype_r1")
        .getValue();
```

然后把已有值一起传给弹窗。

---

## 13.2 只允许在 Equipment Type 为空时显示按钮

可以增加命令规则：

```javascript
EquipmentRepairCommand.canSelectEquipmentType =
    function (primaryControl) {
        "use strict";

        if (!primaryControl) {
            return false;
        }

        var recordId =
            primaryControl.data.entity.getId();

        if (!recordId) {
            return false;
        }

        var attribute =
            primaryControl.getAttribute(
                "demo_equipmenttype_r1"
            );

        if (!attribute) {
            return true;
        }

        return !attribute.getValue();
    };
```

---

## 13.3 保存成功后显示提示

在更新成功后、关闭弹窗前增加：

```javascript
await xrm.Navigation.openAlertDialog({
    title: "Success",
    text: "Equipment Type was updated successfully."
});
```

---

## 13.4 使用 Custom API 和 Plug-in

当前方案由前端直接执行：

```text
Xrm.WebApi.updateRecord()
```

如果后续业务逻辑复杂，可以升级成：

```text
HTML Web Resource
→ Custom API
→ C# Plug-in
→ 更新 Equipment Repair Request
→ 写审计记录
→ 返回结果
```

适用场景包括：

- 需要服务端权限校验
- 需要多个表在同一事务中更新
- 需要创建审计记录
- 需要状态校验
- 需要防止前端绕过业务逻辑

---

# 14. 最终关键参数汇总

```javascript
const MAIN_TABLE_LOGICAL_NAME =
    "demo_equipmentrepairrequest";

const MAIN_TABLE_ENTITY_SET_NAME =
    "demo_equipmentrepairrequests";

const TARGET_TABLE_LOGICAL_NAME =
    "demo_equipmenttype";

const TARGET_TABLE_ENTITY_SET_NAME =
    "demo_equipmenttypes";

const LOOKUP_COLUMN_OR_NAVIGATION_PROPERTY =
    "demo_equipmenttype_r1";
```

最终更新 Lookup 的核心代码：

```javascript
var updateData = {};

updateData[
    "demo_equipmenttype_r1@odata.bind"
] =
    "/demo_equipmenttypes(" +
    selectedEquipmentTypeId +
    ")";

await Xrm.WebApi.updateRecord(
    "demo_equipmentrepairrequest",
    equipmentRepairRequestId,
    updateData
);
```

> 上述代码中的 `demo_equipmenttype_r1` 必须以 Metadata Browser 中确认的 `ReferencingEntityNavigationPropertyName` 为准。
