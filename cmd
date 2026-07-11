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

console.log("D365Dialog library loaded.");

export { DialogService, SampleCommands };



const script = document.createElement("script");

script.src =
  Xrm.Utility.getGlobalContext().getClientUrl() +
  "/WebResources/new_/D365Dialog/d365dialog.min.js?time=" +
  Date.now();

script.onload = function () {
  console.log("Script loaded manually");
  console.log("D365Dialog type:", typeof window.D365Dialog);
};

script.onerror = function (event) {
  console.error("Script load failed", event, script.src);
};

document.head.appendChild(script);

function onFormLoad(executionContext) {
    var formContext = executionContext.getFormContext();
    Ripple.Utils.NotificationHelper.init(formContext, "zh");
    Ripple.Utils.NotificationHelper.showFormMessage("工具库加载成功", "INFO", "init_test");
}


