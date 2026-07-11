var isSavingViaHandler = false;

function onFormLoad(executionContext) {
    var formContext = executionContext.getFormContext();
    Ripple.Utils.NotificationHelper.init(formContext, "en");

    formContext.data.entity.addOnSave(function (econtext) {
        if (isSavingViaHandler) {
            // 这是我们自己发起的保存，放行，不要再拦截
            return;
        }
        econtext.getEventArgs().preventDefault();
        handleSave(formContext);
    });
}

async function handleSave(formContext) {
    try {
        isSavingViaHandler = true;
        await formContext.data.save();
    } catch (error) {
        console.log("原始错误：", error);
        await Ripple.Utils.NotificationHelper.handlePluginError(error);
    } finally {
        isSavingViaHandler = false;
    }
}
