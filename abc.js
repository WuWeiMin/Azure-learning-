var AIA = AIA || {};
AIA.ThresholdInput = (function () {
    var FIELD = "aia_threshold";
    var MSGID = "thresholdFmt";
    // 接受 H:MM:SS / HH:MM:SS,分秒必须两位且<60
    var RE = /^(\d{1,3}):([0-5]\d):([0-5]\d)$/;

    // OnChange: 校验 + 规范化 + 补零
    function onChange(executionContext) {
        var fc = executionContext.getFormContext();
        var attr = fc.getAttribute(FIELD);
        var ctrl = fc.getControl(FIELD);
        var v = (attr.getValue() || "").trim();

        if (!v) {                                   // 允许留空
            ctrl.clearNotification(MSGID);
            return;
        }

        // 便利输入: 纯数字自动格式化, "2205"→"00:22:05", "5"→"00:00:05"
        if (/^\d{1,6}$/.test(v)) {
            v = v.padStart(6, "0");
            v = v.slice(0,2) + ":" + v.slice(2,4) + ":" + v.slice(4,6);
        }

        var m = RE.exec(v);
        if (m) {
            // 规范化补零后写回 (如 "0:05:00" → "00:05:00")
            var norm = m[1].padStart(2, "0") + ":" + m[2] + ":" + m[3];
            if (norm !== attr.getValue()) attr.setValue(norm);
            ctrl.clearNotification(MSGID);
        } else {
            // 字段级红叉提示(比表单顶部通知更醒目)
            ctrl.setNotification("格式须为 HH:MM:SS,例如 00:22:05", MSGID);
        }
    }

    // OnSave: 最后防线,格式不对阻止保存
    function onSave(executionContext) {
        var fc = executionContext.getFormContext();
        var v = (fc.getAttribute(FIELD).getValue() || "").trim();
        if (v && !RE.test(v)) {
            executionContext.getEventArgs().preventDefault();
            fc.ui.setFormNotification(
                "阈值格式不正确, 须为 HH:MM:SS", "ERROR", MSGID);
        } else {
            fc.ui.clearFormNotification(MSGID);
        }
    }

    return { onChange: onChange, onSave: onSave };
})();
