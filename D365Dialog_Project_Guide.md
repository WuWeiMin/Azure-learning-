# D365Dialog 项目创建与实施指南

> 适用环境：Dynamics 365 Online / Dataverse / Model-driven App 9.2.x  
> 当前目标环境：Server version `9.2.26063`  
> 技术方案：TypeScript + esbuild + `@types/xrm` + JavaScript Web Resource

---

## 1. 项目目标

本项目用于建立一个可复用的 Dynamics 365 Dialog 封装库，使 Ribbon、Command Bar、表单 JavaScript 和 HTML Web Resource 不再直接调用零散的 `Xrm.Navigation` API。

第一阶段公开以下 API：

```typescript
D365Dialog.alert(...)
D365Dialog.confirm(...)
D365Dialog.error(...)
D365Dialog.openEntity(...)
D365Dialog.openWebResource(...)
D365Dialog.openCustomPage(...)
```

最终业务代码应类似：

```typescript
const confirmed = await D365Dialog.confirm({
    title: "Confirm",
    text: "Are you sure you want to submit this record?"
});

if (!confirmed) {
    return;
}
```

而不是在每个功能中重复创建 `pageInput`、`navigationOptions` 和 Promise 回调。

---

## 2. 技术原则

1. 只使用 Microsoft 支持的 Client API。
2. 底层统一使用 `Xrm.Navigation`。
3. `navigateTo` 使用 `target: 2` 打开 Modal Dialog。
4. 对业务代码隐藏 Dynamics 原始参数结构。
5. 所有异步方法统一使用 `async/await`。
6. 第一版不引入 React，先减少依赖和部署复杂度。
7. 第一版不实现复杂跨窗口返回值；待基础功能稳定后再增加 `DialogMessageBus`。

Microsoft 当前文档说明：

- `Xrm.Navigation.navigateTo` 可打开实体记录、HTML Web Resource、Custom Page 等页面。
- `target: 2` 表示以 Dialog 方式打开。
- `openAlertDialog`、`openConfirmDialog`、`openErrorDialog` 是当前支持的原生对话框 API。

官方参考：

- https://learn.microsoft.com/power-apps/developer/model-driven-apps/clientapi/reference/xrm-navigation
- https://learn.microsoft.com/power-apps/developer/model-driven-apps/clientapi/reference/xrm-navigation/navigateto
- https://learn.microsoft.com/power-apps/developer/model-driven-apps/clientapi/reference/xrm-navigation/openalertdialog
- https://learn.microsoft.com/power-apps/developer/model-driven-apps/clientapi/reference/xrm-navigation/openconfirmdialog
- https://learn.microsoft.com/power-apps/developer/model-driven-apps/clientapi/reference/xrm-navigation/openerrordialog

---

# 第一部分：创建 TypeScript 项目

## 3. 前置条件

本地安装：

- Node.js 20 或更高版本
- npm
- Visual Studio Code
- Dynamics 365 Solution 自定义权限
- 可上传 JavaScript 和 HTML Web Resource

检查版本：

```powershell
node --version
npm --version
```

建议 Node.js 使用当前受支持的 LTS 版本。

---

## 4. 创建项目目录

在本地建立项目目录：

```powershell
mkdir D365Dialog
cd D365Dialog
code .
```

初始化 npm：

```powershell
npm init -y
```

安装开发依赖：

```powershell
npm install --save-dev typescript esbuild @types/xrm
```

说明：

- `typescript`：编写和检查 TypeScript。
- `esbuild`：将多个 TypeScript 文件打包成一个浏览器 JavaScript 文件。
- `@types/xrm`：为 Dynamics Client API 提供 TypeScript 类型声明。

---

## 5. 创建目录结构

建立以下结构：

```text
D365Dialog/
├─ src/
│  ├─ dialog/
│  │  ├─ DialogTypes.ts
│  │  ├─ DialogService.ts
│  │  └─ index.ts
│  ├─ commands/
│  │  └─ SampleCommands.ts
│  └─ main.ts
├─ webresources/
│  └─ test-dialog/
│     ├─ test-dialog.html
│     └─ test-dialog.js
├─ dist/
├─ package.json
├─ tsconfig.json
└─ README.md
```

PowerShell 创建命令：

```powershell
mkdir src
mkdir src\dialog
mkdir src\commands
mkdir webresources
mkdir webresources\test-dialog
mkdir dist
```

---

## 6. 配置 TypeScript

在项目根目录创建 `tsconfig.json`：

```json
{
  "compilerOptions": {
    "target": "ES2019",
    "module": "ESNext",
    "moduleResolution": "Node",
    "strict": true,
    "noImplicitAny": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "types": ["xrm"],
    "lib": ["ES2019", "DOM"],
    "outDir": "dist"
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

执行类型检查：

```powershell
npx tsc --noEmit
```

此时因为源码尚未创建，可能不会输出任何内容，这是正常现象。

---

## 7. 配置 npm scripts

修改 `package.json` 中的 `scripts`：

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "npm run typecheck && esbuild src/main.ts --bundle --platform=browser --target=es2019 --format=iife --global-name=D365DialogBundle --outfile=dist/new_d365dialog.js",
    "build:min": "npm run typecheck && esbuild src/main.ts --bundle --minify --sourcemap --platform=browser --target=es2019 --format=iife --global-name=D365DialogBundle --outfile=dist/new_d365dialog.min.js",
    "watch": "esbuild src/main.ts --bundle --platform=browser --target=es2019 --format=iife --global-name=D365DialogBundle --outfile=dist/new_d365dialog.js --watch"
  }
}
```

注意：不要删除 `dependencies`、`devDependencies` 等其他现有内容。

---

# 第二部分：定义 Dialog 类型

## 8. 创建 `DialogTypes.ts`

路径：

```text
src/dialog/DialogTypes.ts
```

内容：

```typescript
export type DialogPosition = 1 | 2;
export type DialogUnit = "px" | "%";

export interface DialogDimension {
    value: number;
    unit: DialogUnit;
}

export interface BaseDialogOptions {
    title?: string;
    width?: number | DialogDimension;
    height?: number | DialogDimension;
    position?: DialogPosition;
}

export interface AlertDialogOptions {
    title?: string;
    text: string;
    confirmButtonLabel?: string;
    width?: number;
    height?: number;
}

export interface ConfirmDialogOptions {
    title?: string;
    subtitle?: string;
    text: string;
    confirmButtonLabel?: string;
    cancelButtonLabel?: string;
    width?: number;
    height?: number;
}

export interface ErrorDialogOptions {
    message?: string;
    details?: string;
    errorCode?: number;
}

export interface WebResourceDialogOptions<TData = unknown>
    extends BaseDialogOptions {
    webResourceName: string;
    data?: TData;
}

export interface EntityDialogOptions extends BaseDialogOptions {
    entityName: string;
    entityId?: string;
    formId?: string;
    createFromEntity?: Xrm.Navigation.CreateFromEntity;
}

export interface CustomPageDialogOptions extends BaseDialogOptions {
    pageName: string;
    entityName?: string;
    recordId?: string;
}
```

说明：

- `position: 1`：居中显示。
- `position: 2`：右侧显示。
- 数字宽高默认按像素处理。
- `{ value: 70, unit: "%" }` 可使用百分比。

---

# 第三部分：实现 DialogService

## 9. 创建 `DialogService.ts`

路径：

```text
src/dialog/DialogService.ts
```

内容：

```typescript
import {
    AlertDialogOptions,
    BaseDialogOptions,
    ConfirmDialogOptions,
    CustomPageDialogOptions,
    DialogDimension,
    EntityDialogOptions,
    ErrorDialogOptions,
    WebResourceDialogOptions
} from "./DialogTypes";

export class DialogService {
    /**
     * 显示单按钮提示框。
     */
    public static async alert(
        options: AlertDialogOptions
    ): Promise<void> {
        if (!options.text?.trim()) {
            throw new Error("Alert dialog text is required.");
        }

        const alertStrings: Xrm.Navigation.AlertStrings = {
            text: options.text,
            title: options.title,
            confirmButtonLabel: options.confirmButtonLabel
        };

        const alertOptions: Xrm.Navigation.DialogSizeOptions = {
            width: options.width,
            height: options.height
        };

        await Xrm.Navigation.openAlertDialog(
            alertStrings,
            alertOptions
        );
    }

    /**
     * 显示确认框，并直接返回 true 或 false。
     */
    public static async confirm(
        options: ConfirmDialogOptions
    ): Promise<boolean> {
        if (!options.text?.trim()) {
            throw new Error("Confirm dialog text is required.");
        }

        const confirmStrings: Xrm.Navigation.ConfirmStrings = {
            text: options.text,
            title: options.title,
            subtitle: options.subtitle,
            confirmButtonLabel: options.confirmButtonLabel,
            cancelButtonLabel: options.cancelButtonLabel
        };

        const confirmOptions: Xrm.Navigation.DialogSizeOptions = {
            width: options.width,
            height: options.height
        };

        const result = await Xrm.Navigation.openConfirmDialog(
            confirmStrings,
            confirmOptions
        );

        return result.confirmed;
    }

    /**
     * 显示 Dynamics 原生错误窗口。
     */
    public static async error(
        options: ErrorDialogOptions
    ): Promise<void> {
        if (!options.message && options.errorCode === undefined) {
            throw new Error(
                "Error dialog requires message or errorCode."
            );
        }

        await Xrm.Navigation.openErrorDialog({
            message: options.message,
            details: options.details,
            errorCode: options.errorCode
        });
    }

    /**
     * 在 Modal Dialog 中打开 HTML Web Resource。
     */
    public static async openWebResource<TData = unknown>(
        options: WebResourceDialogOptions<TData>
    ): Promise<void> {
        if (!options.webResourceName?.trim()) {
            throw new Error("Web Resource name is required.");
        }

        const pageInput = {
            pageType: "webresource",
            webresourceName: options.webResourceName,
            data: this.serializeData(options.data)
        } as Xrm.Navigation.PageInputHtmlWebResource;

        await Xrm.Navigation.navigateTo(
            pageInput,
            this.buildNavigationOptions(options)
        );
    }

    /**
     * 在 Modal Dialog 中打开已有记录或新建表单。
     */
    public static async openEntity(
        options: EntityDialogOptions
    ): Promise<unknown> {
        if (!options.entityName?.trim()) {
            throw new Error("Entity logical name is required.");
        }

        const pageInput = {
            pageType: "entityrecord",
            entityName: options.entityName,
            entityId: this.normalizeGuid(options.entityId),
            formId: this.normalizeGuid(options.formId),
            createFromEntity: options.createFromEntity
        } as Xrm.Navigation.PageInputEntityRecord;

        return Xrm.Navigation.navigateTo(
            pageInput,
            this.buildNavigationOptions(options)
        );
    }

    /**
     * 在 Modal Dialog 中打开 Custom Page。
     */
    public static async openCustomPage(
        options: CustomPageDialogOptions
    ): Promise<void> {
        if (!options.pageName?.trim()) {
            throw new Error("Custom Page unique name is required.");
        }

        const pageInput = {
            pageType: "custom",
            name: options.pageName,
            entityName: options.entityName,
            recordId: this.normalizeGuid(options.recordId)
        } as Xrm.Navigation.CustomPage;

        await Xrm.Navigation.navigateTo(
            pageInput,
            this.buildNavigationOptions(options)
        );
    }

    /**
     * 将输入数据序列化为 Web Resource data 参数。
     */
    public static serializeData<TData>(
        data: TData | undefined
    ): string | undefined {
        if (data === undefined || data === null) {
            return undefined;
        }

        return encodeURIComponent(JSON.stringify(data));
    }

    /**
     * 解析 Web Resource URL 中的 data 参数。
     * 此方法也可以复制到独立 HTML Web Resource 中使用。
     */
    public static parseData<TData>(
        search: string = window.location.search
    ): TData | null {
        const query = new URLSearchParams(search);
        const rawValue = query.get("data");

        if (!rawValue) {
            return null;
        }

        try {
            return JSON.parse(
                decodeURIComponent(rawValue)
            ) as TData;
        } catch (error) {
            console.error(
                "Failed to parse dialog data.",
                error
            );
            return null;
        }
    }

    private static buildNavigationOptions(
        options: BaseDialogOptions
    ): Xrm.Navigation.NavigationOptions {
        return {
            target: 2,
            position: options.position ?? 1,
            title: options.title,
            width: this.toNavigationDimension(
                options.width,
                { value: 60, unit: "%" }
            ),
            height: this.toNavigationDimension(
                options.height,
                { value: 70, unit: "%" }
            )
        };
    }

    private static toNavigationDimension(
        input: number | DialogDimension | undefined,
        fallback: DialogDimension
    ): number | Xrm.Navigation.NavigationOptionsSize {
        if (typeof input === "number") {
            return input;
        }

        return input ?? fallback;
    }

    private static normalizeGuid(
        value?: string
    ): string | undefined {
        if (!value) {
            return undefined;
        }

        return value.replace(/[{}]/g, "");
    }
}
```

### 类型版本差异说明

`@types/xrm` 不同版本对部分类型名称可能存在细微差异。如果以下类型在 VS Code 中显示错误：

```typescript
Xrm.Navigation.NavigationOptionsSize
Xrm.Navigation.CustomPage
Xrm.Navigation.PageInputHtmlWebResource
```

可以把对应位置暂时改为本项目自己的结构类型，或在局部使用类型断言。不要将整个项目改成 `any`。

例如：

```typescript
interface NavigationSize {
    value: number;
    unit: "px" | "%";
}
```

然后将：

```typescript
number | Xrm.Navigation.NavigationOptionsSize
```

改成：

```typescript
number | NavigationSize
```

---

## 10. 创建统一导出文件

路径：

```text
src/dialog/index.ts
```

内容：

```typescript
export { DialogService } from "./DialogService";
export * from "./DialogTypes";
```

---

# 第四部分：暴露全局 API

## 11. 创建 `main.ts`

Dynamics Ribbon 和 Form Library 通常通过全局函数名调用，因此需要将服务挂载到 `window`。

路径：

```text
src/main.ts
```

内容：

```typescript
import { DialogService } from "./dialog";
import { SampleCommands } from "./commands/SampleCommands";

declare global {
    interface Window {
        D365Dialog: typeof DialogService;
        D365Commands: typeof SampleCommands;
    }
}

window.D365Dialog = DialogService;
window.D365Commands = SampleCommands;

export { DialogService, SampleCommands };
```

构建后，Dynamics 中可以直接调用：

```javascript
D365Dialog.alert(...)
```

以及：

```javascript
D365Commands.testAlert(primaryControl)
```

---

# 第五部分：创建测试 Command

## 12. 创建 `SampleCommands.ts`

路径：

```text
src/commands/SampleCommands.ts
```

内容：

```typescript
import { DialogService } from "../dialog";

export class SampleCommands {
    public static async testAlert(
        primaryControl: Xrm.FormContext
    ): Promise<void> {
        try {
            const recordName =
                primaryControl.data.entity.getPrimaryAttributeValue();

            await DialogService.alert({
                title: "D365Dialog Test",
                text: recordName
                    ? `Current record: ${recordName}`
                    : "D365Dialog is working correctly.",
                confirmButtonLabel: "OK"
            });
        } catch (error) {
            await this.handleError(error);
        }
    }

    public static async testConfirm(
        primaryControl: Xrm.FormContext
    ): Promise<void> {
        try {
            const confirmed = await DialogService.confirm({
                title: "Submit Record",
                text: "Are you sure you want to submit this record?",
                confirmButtonLabel: "Submit",
                cancelButtonLabel: "Cancel"
            });

            if (!confirmed) {
                return;
            }

            primaryControl.getAttribute("description")
                ?.setValue("Confirmed from D365Dialog test.");

            await DialogService.alert({
                title: "Completed",
                text: "The description field was updated."
            });
        } catch (error) {
            await this.handleError(error);
        }
    }

    public static async testEntityDialog(
        primaryControl: Xrm.FormContext
    ): Promise<void> {
        try {
            const recordId =
                primaryControl.data.entity.getId();

            await DialogService.openEntity({
                title: "Current Record",
                entityName:
                    primaryControl.data.entity.getEntityName(),
                entityId: recordId,
                width: { value: 75, unit: "%" },
                height: { value: 80, unit: "%" }
            });

            await primaryControl.data.refresh(false);
        } catch (error) {
            await this.handleError(error);
        }
    }

    public static async testWebResourceDialog(
        primaryControl: Xrm.FormContext
    ): Promise<void> {
        try {
            await DialogService.openWebResource({
                title: "Dialog Test",
                webResourceName:
                    "new_/d365dialog/test-dialog.html",
                data: {
                    entityName:
                        primaryControl.data.entity.getEntityName(),
                    recordId:
                        primaryControl.data.entity.getId(),
                    recordName:
                        primaryControl.data.entity
                            .getPrimaryAttributeValue()
                },
                width: 720,
                height: 480
            });
        } catch (error) {
            await this.handleError(error);
        }
    }

    public static async testCustomPageDialog(
        primaryControl: Xrm.FormContext
    ): Promise<void> {
        try {
            await DialogService.openCustomPage({
                title: "Custom Page Test",
                pageName: "new_dialogpage_12345",
                entityName:
                    primaryControl.data.entity.getEntityName(),
                recordId:
                    primaryControl.data.entity.getId(),
                width: { value: 70, unit: "%" },
                height: { value: 75, unit: "%" }
            });
        } catch (error) {
            await this.handleError(error);
        }
    }

    private static async handleError(
        error: unknown
    ): Promise<void> {
        const message = error instanceof Error
            ? error.message
            : "An unexpected error occurred.";

        console.error(error);

        await DialogService.error({
            message,
            details: error instanceof Error
                ? error.stack
                : String(error)
        });
    }
}
```

注意：

- 示例中的 `description` 字段只适用于具有该字段的表。
- 如果当前表没有 `description`，请改成你们表中实际存在的文本字段。
- `new_dialogpage_12345` 必须替换成真实 Custom Page 的 Unique Name。

---

# 第六部分：创建测试 HTML Web Resource

## 13. 创建 `test-dialog.html`

路径：

```text
webresources/test-dialog/test-dialog.html
```

内容：

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta
        name="viewport"
        content="width=device-width, initial-scale=1"
    />
    <title>D365Dialog Test</title>
    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 24px;
            font-family: "Segoe UI", Arial, sans-serif;
            color: #242424;
            background: #ffffff;
        }

        .container {
            max-width: 680px;
            margin: 0 auto;
        }

        h1 {
            margin: 0 0 20px;
            font-size: 24px;
            font-weight: 600;
        }

        .row {
            margin-bottom: 14px;
        }

        .label {
            display: block;
            margin-bottom: 4px;
            font-weight: 600;
        }

        .value {
            padding: 10px;
            border: 1px solid #d1d1d1;
            background: #fafafa;
            overflow-wrap: anywhere;
        }

        .actions {
            display: flex;
            justify-content: flex-end;
            gap: 8px;
            margin-top: 24px;
        }

        button {
            min-width: 96px;
            padding: 8px 16px;
            border: 1px solid #8a8886;
            background: #ffffff;
            cursor: pointer;
            font: inherit;
        }

        button.primary {
            border-color: #0f6cbd;
            color: #ffffff;
            background: #0f6cbd;
        }

        .error {
            color: #a4262c;
        }
    </style>
</head>
<body>
    <main class="container">
        <h1>HTML Web Resource Dialog</h1>

        <div id="content"></div>

        <div class="actions">
            <button type="button" id="cancelButton">
                Cancel
            </button>
            <button
                type="button"
                id="okButton"
                class="primary"
            >
                OK
            </button>
        </div>
    </main>

    <script src="new_/d365dialog/test-dialog.js"></script>
</body>
</html>
```

### 关于脚本路径

HTML Web Resource 引用其他 Web Resource 时，路径处理可能受发布名称影响。

更稳妥的两种方式：

1. 将 JavaScript 直接嵌入 HTML，适合测试。
2. 将 HTML 和 JavaScript 放在相同虚拟目录，并根据实际 Web Resource 名称调整 `src`。

如果外部脚本无法加载，先将下一节的 JavaScript 放进 HTML 最底部的 `<script>` 标签内验证。

---

## 14. 创建 `test-dialog.js`

路径：

```text
webresources/test-dialog/test-dialog.js
```

内容：

```javascript
(function () {
    "use strict";

    function parseDialogData() {
        const query = new URLSearchParams(
            window.location.search
        );

        const rawValue = query.get("data");

        if (!rawValue) {
            return null;
        }

        try {
            return JSON.parse(
                decodeURIComponent(rawValue)
            );
        } catch (error) {
            console.error(
                "Failed to parse dialog data.",
                error
            );
            return null;
        }
    }

    function encodeHtml(value) {
        const element = document.createElement("div");
        element.textContent = value ?? "";
        return element.innerHTML;
    }

    function render() {
        const content = document.getElementById("content");
        const data = parseDialogData();

        if (!data) {
            content.innerHTML =
                '<p class="error">No dialog data was received.</p>';
            return;
        }

        content.innerHTML = `
            <div class="row">
                <span class="label">Entity Name</span>
                <div class="value">${encodeHtml(data.entityName)}</div>
            </div>
            <div class="row">
                <span class="label">Record ID</span>
                <div class="value">${encodeHtml(data.recordId)}</div>
            </div>
            <div class="row">
                <span class="label">Record Name</span>
                <div class="value">${encodeHtml(data.recordName)}</div>
            </div>
        `;
    }

    function closeDialog() {
        window.close();
    }

    document
        .getElementById("cancelButton")
        .addEventListener("click", closeDialog);

    document
        .getElementById("okButton")
        .addEventListener("click", closeDialog);

    render();
})();
```

安全说明：示例使用 `textContent` 间接进行 HTML 编码，避免把未经处理的业务数据直接插入页面造成 XSS 风险。

---

# 第七部分：构建项目

## 15. 执行类型检查

```powershell
npm run typecheck
```

必须先解决所有 TypeScript 错误。

常见问题：

### 问题一：找不到 `Xrm`

检查：

```powershell
npm list @types/xrm
```

确认 `tsconfig.json` 中包含：

```json
"types": ["xrm"]
```

### 问题二：某个 Xrm 类型不存在

这是 `@types/xrm` 版本差异造成的。优先升级：

```powershell
npm install --save-dev @types/xrm@latest
```

仍有问题时，对那个局部结构建立自己的 interface，不要取消整个项目的严格模式。

---

## 16. 生成开发版文件

```powershell
npm run build
```

成功后产生：

```text
dist/new_d365dialog.js
```

生成生产压缩版：

```powershell
npm run build:min
```

输出：

```text
dist/new_d365dialog.min.js
dist/new_d365dialog.min.js.map
```

建议：

- 开发和测试环境使用 `new_d365dialog.js`。
- 生产环境使用压缩版。
- Source map 是否上传应遵守公司安全规范。

---

# 第八部分：上传到 Dynamics 365

## 17. 创建 Solution

进入：

```text
Power Apps Maker Portal
→ Solutions
→ New solution
```

建议：

```text
Display name: D365 Dialog Framework
Name: D365DialogFramework
Publisher: 使用公司已有 Publisher
Version: 1.0.0.0
```

不要在正式项目中使用默认 Publisher。

---

## 18. 上传 JavaScript Web Resource

在 Solution 中：

```text
New
→ More
→ Web resource
```

建议配置：

```text
Name: new_/d365dialog/new_d365dialog.js
Display Name: D365 Dialog Library
Type: Script (JScript)
Language: English
File: dist/new_d365dialog.js
```

保存并发布。

重要：代码示例中的 Web Resource 名称必须与这里完全一致。

---

## 19. 上传测试 HTML 和 JavaScript

HTML：

```text
Name: new_/d365dialog/test-dialog.html
Type: Webpage (HTML)
File: webresources/test-dialog/test-dialog.html
```

JavaScript：

```text
Name: new_/d365dialog/test-dialog.js
Type: Script (JScript)
File: webresources/test-dialog/test-dialog.js
```

保存并发布全部自定义项。

---

# 第九部分：表单中测试

## 20. 将 Library 添加到表单

打开目标表的 Main Form：

```text
Form Designer
→ Form libraries
→ Add library
```

选择：

```text
new_/d365dialog/new_d365dialog.js
```

保存并发布表单。

提醒：

- 若只在 Command Bar 使用，有些命令工具会自动添加 Library。
- 为避免首次测试时资源未加载，建议先显式添加到 Form libraries。

---

## 21. 使用浏览器 Console 测试

打开一条记录，按 `F12` 打开开发者工具，在 Console 执行：

```javascript
D365Dialog.alert({
    title: "Test",
    text: "D365Dialog loaded successfully."
});
```

测试 Confirm：

```javascript
D365Dialog.confirm({
    title: "Confirm",
    text: "Is the component working?"
}).then(function (confirmed) {
    console.log("Confirmed:", confirmed);
});
```

如果出现：

```text
D365Dialog is not defined
```

检查：

1. JavaScript Web Resource 是否已发布。
2. 表单是否添加 Library。
3. 浏览器是否加载了旧缓存。
4. Web Resource 是否存在构建错误。
5. `main.ts` 是否执行了 `window.D365Dialog = DialogService`。

可使用无痕窗口或清理浏览器缓存再次测试。

---

# 第十部分：Command Bar / Ribbon 测试

## 22. Command 函数名称

Ribbon Workbench 或现代 Command Designer 中调用：

```text
D365Commands.testAlert
```

参数传入：

```text
PrimaryControl
```

其他测试函数：

```text
D365Commands.testConfirm
D365Commands.testEntityDialog
D365Commands.testWebResourceDialog
D365Commands.testCustomPageDialog
```

注意：

- 函数名称不要加括号。
- `PrimaryControl` 应作为参数传入。
- 需要确保命令加载 `new_/d365dialog/new_d365dialog.js`。

---

## 23. Ribbon Workbench 配置示例

按钮 Command Action：

```text
Action Type: JavaScript Action
Library: $webresource:new_/d365dialog/new_d365dialog.js
Function Name: D365Commands.testWebResourceDialog
Parameter: PrimaryControl
```

发布后打开记录表单测试。

---

# 第十一部分：验收标准

## 24. 第一阶段功能验收

逐项确认：

| 编号 | 测试项 | 预期结果 |
|---|---|---|
| 1 | `alert` | 显示一个按钮的原生提示框 |
| 2 | `confirm` 点击确认 | Promise 返回 `true` |
| 3 | `confirm` 点击取消 | Promise 返回 `false` |
| 4 | `error` | 显示 Dynamics 原生错误框 |
| 5 | `openEntity` | 当前或指定记录以 Modal 打开 |
| 6 | `openWebResource` | HTML Web Resource 以 Modal 打开 |
| 7 | Web Resource 参数 | 正确显示 entityName、recordId、recordName |
| 8 | `openCustomPage` | Custom Page 以 Modal 打开 |
| 9 | Ribbon 调用 | Command 能访问全局函数 |
| 10 | 异常处理 | 错误进入 `openErrorDialog` |

第一阶段完成标准：以上 10 项全部通过。

---

# 第十二部分：第二阶段——返回值机制

## 25. 为什么先不把返回值塞进第一版

`openConfirmDialog` 会直接返回 `confirmed`，但普通 HTML Web Resource 和 Custom Page 并没有统一的强类型 `Promise<TResult>` 返回机制。

因此第二阶段应增加：

```typescript
D365Dialog.open<TInput, TResult>(...)
```

目标调用方式：

```typescript
const result = await D365Dialog.open<
    AssignAccessInput,
    AssignAccessResult
>({
    webResourceName: "new_/dialogs/assign-access.html",
    data: {
        recordId
    }
});
```

Dialog 内部：

```typescript
D365DialogHost.close({
    confirmed: true,
    selectedUserId: userId
});
```

---

## 26. 推荐返回值架构

```text
调用页面
  │
  ├─ 生成 dialogId
  ├─ 注册 Promise resolver
  ├─ navigateTo HTML Web Resource
  │
Dialog 页面
  ├─ 从 URL 读取 dialogId 和 input
  ├─ 用户完成操作
  ├─ window.parent.postMessage(result)
  │
调用页面
  ├─ 验证 origin
  ├─ 验证 dialogId
  ├─ resolve Promise
  └─ 删除 resolver
```

必须包含：

- `dialogId` 唯一标识。
- `event.origin` 校验。
- 消息类型校验。
- 超时处理。
- 重复返回保护。
- resolver 清理。
- Cancel 返回结构。
- Dialog 被用户直接关闭时的处理。

不要只凭消息名称接收任意 `postMessage`。

---

## 27. 第二阶段建议文件

```text
src/dialog/
├─ DialogTypes.ts
├─ DialogService.ts
├─ DialogRegistry.ts
├─ DialogMessageBus.ts
├─ DialogHost.ts
└─ index.ts
```

建议结果结构：

```typescript
export interface DialogResult<TData = unknown> {
    confirmed: boolean;
    cancelled: boolean;
    data?: TData;
}
```

消息结构：

```typescript
export interface DialogResultMessage<TData = unknown> {
    type: "D365_DIALOG_RESULT";
    dialogId: string;
    result: DialogResult<TData>;
}
```

---

# 第十三部分：第三阶段——React 与 Fluent UI

## 28. 何时引入 React

只有出现以下需求时再引入：

- 多步骤 Wizard。
- 复杂输入表单。
- Grid 选择器。
- Lookup 组合控件。
- Tab 页面。
- 统一 Loading、Error、Empty State。
- 大量可复用 UI 控件。

不建议仅为了一个简单确认框引入 React。

未来结构：

```text
HTML Web Resource
└─ React Root
   └─ Fluent UI
      ├─ Dialog Layout
      ├─ Form
      ├─ Footer Buttons
      └─ Message Bar
```

---

# 第十四部分：版本管理和发布

## 29. 建议版本规则

```text
1.0.0  第一版原生 API 封装
1.1.0  增加配置默认值和日志
1.2.0  增加 DialogMessageBus
1.3.0  增加强类型结果
2.0.0  React / Fluent UI Host
```

使用语义版本：

```text
Major.Minor.Patch
```

- Major：破坏兼容性的修改。
- Minor：向后兼容的新功能。
- Patch：向后兼容的 Bug 修复。

---

## 30. 建议 Git 提交顺序

```text
chore: initialize TypeScript and esbuild project
feat: add dialog option types
feat: implement alert confirm and error dialogs
feat: implement entity dialog
feat: implement web resource dialog
feat: implement custom page dialog
feat: expose global D365Dialog API
feat: add ribbon command examples
feat: add HTML web resource example
docs: add deployment and testing guide
```

---

# 第十五部分：常见问题

## 31. `window.close()` 没有关闭 Dialog

先确认页面确实是通过：

```typescript
Xrm.Navigation.navigateTo(pageInput, {
    target: 2
});
```

打开，而不是普通浏览器标签页。

如果特定页面类型下关闭行为不同，应优先使用该页面类型支持的官方导航方式，不要访问 `Xrm.Internal` 等未支持 API。

---

## 32. `navigateTo` 打开成整页而不是 Dialog

检查：

```typescript
target: 2
```

`target: 1` 表示 inline。

---

## 33. 百分比宽高没有生效

使用：

```typescript
width: {
    value: 70,
    unit: "%"
}
```

不要写成字符串：

```typescript
width: "70%"
```

---

## 34. Record ID 带大括号

Dynamics 表单返回值可能类似：

```text
{9DFA...1234}
```

本项目的 `normalizeGuid` 会移除 `{}`。

---

## 35. HTML Web Resource 收不到数据

检查以下几点：

1. `pageInput.data` 是否有值。
2. 是否对数据执行了 `JSON.stringify`。
3. 是否执行了 `encodeURIComponent`。
4. HTML 页面是否读取 URL 中的 `data` 参数。
5. 是否错误地重复解码。
6. 数据是否过大。

不要通过 URL 传递：

- 密码。
- Token。
- 个人敏感数据。
- 大体积 JSON。

复杂数据应只传 record ID，再由页面通过 Dataverse Web API 查询。

---

## 36. 是否应该使用 `Xrm.Internal`

不应该。

以下模式不应进入本项目：

```javascript
Xrm.Internal.*
window.parent.Xrm.Internal.*
Mscrm.*
```

它们不属于稳定的公开 Client API，Dynamics Online 更新后可能失效。

---

# 第十六部分：完成路线图

## 37. 推荐实施节奏

### Sprint 1：基础封装

完成：

```text
alert
confirm
error
openEntity
openWebResource
openCustomPage
```

### Sprint 2：工程化

完成：

```text
全局命名空间
统一错误处理
统一默认尺寸
日志接口
部署脚本
版本号
```

### Sprint 3：返回值

完成：

```text
dialogId
Promise Registry
postMessage
origin validation
timeout
cancel result
```

### Sprint 4：高级 UI

完成：

```text
React
Fluent UI
Prompt
Wizard
Lookup
Grid Selector
Loading
Dirty Check
```

---

# 第十七部分：第一轮实际操作清单

## 38. 现在按照以下顺序执行

1. 创建 `D365Dialog` 目录。
2. 执行 `npm init -y`。
3. 安装 `typescript`、`esbuild`、`@types/xrm`。
4. 创建本文中的目录结构。
5. 创建 `tsconfig.json`。
6. 修改 `package.json` scripts。
7. 创建 `DialogTypes.ts`。
8. 创建 `DialogService.ts`。
9. 创建 `index.ts`。
10. 创建 `SampleCommands.ts`。
11. 创建 `main.ts`。
12. 执行 `npm run typecheck`。
13. 解决类型错误。
14. 执行 `npm run build`。
15. 在 Solution 中上传 JavaScript Web Resource。
16. 上传测试 HTML 和 JavaScript Web Resource。
17. 将 Library 添加到测试表单。
18. 在浏览器 Console 测试 `D365Dialog.alert`。
19. 在 Command Bar 添加测试按钮。
20. 完成第 24 节中的验收测试。

---

## 39. 第一阶段交付物

完成后项目应至少包含：

```text
D365Dialog/
├─ src/
│  ├─ dialog/
│  │  ├─ DialogTypes.ts
│  │  ├─ DialogService.ts
│  │  └─ index.ts
│  ├─ commands/
│  │  └─ SampleCommands.ts
│  └─ main.ts
├─ webresources/
│  └─ test-dialog/
│     ├─ test-dialog.html
│     └─ test-dialog.js
├─ dist/
│  └─ new_d365dialog.js
├─ package.json
└─ tsconfig.json
```

Dynamics Solution 中应包含：

```text
new_/d365dialog/new_d365dialog.js
new_/d365dialog/test-dialog.html
new_/d365dialog/test-dialog.js
```

---

# 40. 最终目标 API

第一阶段：

```typescript
await D365Dialog.alert({
    title: "Information",
    text: "Operation completed."
});

const confirmed = await D365Dialog.confirm({
    title: "Confirm",
    text: "Continue?"
});

await D365Dialog.error({
    message: "Operation failed."
});

await D365Dialog.openEntity({
    entityName: "contact",
    entityId: contactId,
    title: "Contact"
});

await D365Dialog.openWebResource({
    webResourceName: "new_/dialogs/sample.html",
    data: {
        recordId
    },
    title: "Sample Dialog"
});

await D365Dialog.openCustomPage({
    pageName: "new_custompage_unique_name",
    recordId,
    entityName: "account",
    title: "Custom Dialog"
});
```

第二阶段目标：

```typescript
const result = await D365Dialog.open<
    InputModel,
    ResultModel
>({
    page: "new_/dialogs/sample.html",
    data: input
});
```

做到这里以后，我们就拥有一个可持续扩展、符合 Dynamics 365 Online 支持边界、能够供多个项目复用的 Dialog Framework。
