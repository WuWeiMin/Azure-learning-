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
