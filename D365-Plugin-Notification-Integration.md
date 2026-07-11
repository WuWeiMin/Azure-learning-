# D365 插件 ↔ 前端通知库 联动指南

## 目标

C# 插件抛出的异常，按 `[ERRxxx] 具体描述` 格式约定，前端 `NotificationHelper.handlePluginError()`
自动解析错误码，展示对应语言的友好提示，而不是把原始异常堆栈甩给用户看。

---

## Step 1：C# 端错误码常量类

新建 `ErrorCodes.cs`，加到你的插件项目里（建议放在公共/Common 项目，方便多个插件共用）：

```csharp
namespace Ripple.Plugins.Common
{
    public static class ErrorCodes
    {
        public const string REQUIRED_FIELD_MISSING = "ERR001";
        public const string INVALID_FORMAT = "ERR002";
        public const string DUPLICATE_RECORD = "ERR003";
        public const string PLUGIN_EXCEPTION = "ERR004";
        public const string PERMISSION_DENIED = "ERR005";
        public const string SAVE_FAILED = "ERR006";
        public const string UNKNOWN = "ERR999";
    }
}
```

**重要约定：** 这份错误码列表要跟前端 `src/ErrorCodes.ts` 里的 `ErrorCode` 枚举保持完全一致。
以后任何一方加新错误码，都要同步改另一边，否则前端会把未识别的码归到 `UNKNOWN`，
虽然不会报错，但文案会显示"未知错误码"，体验不好。

---

## Step 2：统一异常抛出 Helper

新建 `RippleExceptionHelper.cs`：

```csharp
using System;
using Microsoft.Xrm.Sdk;

namespace Ripple.Plugins.Common
{
    public static class RippleExceptionHelper
    {
        /// <summary>
        /// 抛出带错误码前缀的插件异常，格式固定为 "[ERRxxx] detail"，
        /// 前端 NotificationHelper.handlePluginError() 会自动解析这个格式。
        /// </summary>
        public static InvalidPluginExecutionException Throw(string errorCode, string detail)
        {
            return new InvalidPluginExecutionException($"[{errorCode}] {detail}");
        }
    }
}
```

用这个 helper 而不是每次手写字符串拼接，是为了避免格式写错（比如漏了方括号、
多了个空格），前端的正则匹配对格式比较敏感。

---

## Step 3：插件里的实际用法示例

以校验设备名称必填为例：

```csharp
using System;
using Microsoft.Xrm.Sdk;
using Ripple.Plugins.Common;

namespace Ripple.Plugins.Equipment
{
    public class ValidateEquipmentPlugin : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            var context = (IPluginExecutionContext)serviceProvider
                .GetService(typeof(IPluginExecutionContext));

            var target = (Entity)context.InputParameters["Target"];

            // 场景1：必填字段校验
            if (!target.Contains("demo_equipmentname"))
            {
                throw RippleExceptionHelper.Throw(
                    ErrorCodes.REQUIRED_FIELD_MISSING,
                    "Equipment name is required for demo_equipment entity"
                );
            }

            // 场景2：业务逻辑异常兜底
            try
            {
                // ... 实际业务逻辑，比如调用外部服务、复杂计算等
            }
            catch (Exception ex)
            {
                throw RippleExceptionHelper.Throw(
                    ErrorCodes.PLUGIN_EXCEPTION,
                    $"Unexpected error during equipment validation: {ex.Message}"
                );
            }
        }
    }
}
```

**插件注册建议（用 Plugin Registration Tool）：**
- Message: `Create` 或 `Update`（看你要校验哪个场景）
- Primary Entity: `demo_equipment`（换成你实际的实体名）
- Execution Mode: **Synchronous**（必须同步，否则异常不会实时反馈到表单）
- Execution Stage: **Pre-operation**（在数据写入前拦截，用户能立刻看到错误提示）

---

## Step 4：前端捕获并展示

### 场景A：表单保存时触发的同步插件异常

```javascript
formContext.data.entity.addOnSave(async function (econtext) {
    // 注意：这里捕获不到插件异常，因为插件是在D365内部保存管道里跑的，
    // 真正需要 try/catch 的地方是 Web API 调用（见场景B），
    // 如果是纯表单Save触发的插件报错，D365会自动弹出系统原生错误对话框，
    // 内容就是你抛出的 "[ERR001] xxx" 原始文本 —— 这种情况下无法用
    // handlePluginError 拦截，因为不经过你的JS代码。
    //
    // 如果想要插件错误也走友好提示，需要用场景B的 Custom API 方式，
    // 而不是让插件直接挂在 Create/Update 消息上。
});
```

### 场景B：通过 Custom API 主动调用（推荐，能完整拦截）

如果把校验逻辑包装成一个 **Custom API**（而不是直接挂在 Create/Update 消息上），
前端主动调用时才能真正 try/catch 到异常并交给 `handlePluginError` 处理：

```javascript
async function saveWithValidation(formContext) {
    try {
        const request = {
            entity: {
                demo_equipmentname: formContext.getAttribute("demo_equipmentname").getValue()
                // ... 其他需要传给Custom API的参数
            },
            getMetadata: function () {
                return {
                    boundParameter: null,
                    parameterTypes: {
                        entity: { typeName: "mscrm.demo_equipment", structuralProperty: 5 }
                    },
                    operationType: 0,
                    operationName: "demo_ValidateEquipment" // 你的Custom API唯一名
                };
            }
        };

        await Xrm.WebApi.online.execute(request);

        // 校验通过，走正常保存
        formContext.data.save();
    } catch (error) {
        await Ripple.Utils.NotificationHelper.handlePluginError(error);
    }
}
```

### 场景C：简单直接的测试方式（不依赖 Custom API，先验证解析逻辑本身）

如果暂时不想搭建 Custom API，只想先验证 `handlePluginError` 的解析逻辑对不对，
可以直接在控制台模拟一个错误对象：

```javascript
Ripple.Utils.NotificationHelper.handlePluginError({
    message: "[ERR004] SQL timeout occurred while validating equipment"
});
```

预期效果：弹出一个 `alert` 对话框，标题 "操作失败"（或英文对应文案），
内容是翻译后的 "A server-side error occurred. Please contact your administrator."，
而不是原始的 SQL 错误信息。

---

## 测试路径建议

**先跑通场景C**（纯前端模拟，5分钟能验证），确认 `handlePluginError` 的正则解析、
错误码翻译逻辑没问题。

**再考虑要不要搭场景B**（Custom API），这个工作量更大，涉及：
1. 在插件项目里新建一个 Custom API 定义（Message 名称、参数）
2. 注册插件到这个 Custom API 上
3. 前端改造成主动调用而不是被动等待表单保存触发

如果你们现有插件大多是直接挂在 Create/Update 消息上（不是 Custom API），
场景A提到的限制（D365会自动弹系统原生对话框，绕过你的JS）是要注意的一点——
这种情况下前端拦截不到，用户看到的会是原始 `[ERR001] xxx` 文本，
不会被翻译成友好文案。要解决这个，要么统一改成Custom API模式，
要么在C#插件端直接抛"最终用户可读"的文案（不带错误码前缀），
牺牲掉双语翻译的能力，换取实现简单。

这两种取舍看你们团队实际插件架构习惯，可以先聊聊现状再决定往哪个方向改。

---

## 检查清单

- [ ] `ErrorCodes.cs` 加入插件项目，跟前端 `ErrorCodes.ts` 码值一致
- [ ] `RippleExceptionHelper.cs` 加入插件项目
- [ ] 至少一个插件用 `RippleExceptionHelper.Throw()` 抛出测试异常
- [ ] 场景C：控制台模拟 `handlePluginError` 验证解析逻辑
- [ ] 决定插件是走 Create/Update 直接挂载，还是 Custom API 模式
- [ ] 如果选 Custom API 模式，完成 Step 4 场景B 的前端改造
