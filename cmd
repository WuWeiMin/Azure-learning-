async function onFormLoad(executionContext) {
    var formContext = executionContext.getFormContext();
    Ripple.Utils.NotificationHelper.init(formContext, "en");

    const confirmed = await Ripple.Utils.NotificationHelper.confirm(
        "Do you want to proceed?",
        "Confirm Action"
    );

    if (confirmed) {
        Ripple.Utils.NotificationHelper.showFormMessage("You clicked Yes", "INFO", "confirm_result");
    } else {
        Ripple.Utils.NotificationHelper.showFormMessage("You clicked No", "WARNING", "confirm_result");
    }
}
