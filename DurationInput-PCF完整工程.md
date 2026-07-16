# DurationInput PCF 完整工程(纯npm,无pac)

绑定字段: `demo_threshold`(单行文本,存 `"HH:MM:SS"`)
控件类型: virtual(React + Fluent UI 平台库)
构建: 仅需 Node + npm,`pcf-scripts` 包负责编译打包

## 0. 目录结构(手动创建)

```
DurationInput/                        ← 工程根目录
├── package.json
├── tsconfig.json
├── pcfconfig.json
└── DurationInput/                    ← 控件目录(与控件同名)
    ├── ControlManifest.Input.xml
    ├── index.ts
    └── HHMMSSInput.tsx
```

> `generated/ManifestTypes.d.ts` 由第一次 build 自动生成,不用手建。

---

## 1. package.json(根目录)

```json
{
  "name": "durationinput",
  "version": "1.0.0",
  "description": "HH:MM:SS duration input PCF control",
  "scripts": {
    "build": "pcf-scripts build",
    "clean": "pcf-scripts clean",
    "rebuild": "pcf-scripts rebuild",
    "start": "pcf-scripts start watch",
    "refreshTypes": "pcf-scripts refreshTypes"
  },
  "dependencies": {
    "react": "16.14.0",
    "react-dom": "16.14.0",
    "@fluentui/react": "8.121.1"
  },
  "devDependencies": {
    "@types/node": "^18.19.0",
    "@types/react": "^16.14.0",
    "@types/react-dom": "^16.9.0",
    "pcf-scripts": "^1",
    "pcf-start": "^1",
    "typescript": "^4.9.5"
  }
}
```

## 2. tsconfig.json(根目录)

```json
{
  "extends": "./node_modules/pcf-scripts/tsconfig_base.json",
  "compilerOptions": {
    "jsx": "react",
    "typeRoots": ["node_modules/@types"]
  }
}
```

## 3. pcfconfig.json(根目录)

```json
{
  "outDir": "./out/controls"
}
```

## 4. DurationInput/ControlManifest.Input.xml

```xml
<?xml version="1.0" encoding="utf-8" ?>
<manifest>
  <control namespace="AIA"
           constructor="DurationInput"
           version="0.0.1"
           display-name-key="Duration Input (HH:MM:SS)"
           description-key="三分框时长输入控件, 以 HH:MM:SS 文本形式存储"
           control-type="virtual">

    <external-service-usage enabled="false"></external-service-usage>

    <property name="thresholdValue"
              display-name-key="Threshold (HH:MM:SS)"
              description-key="存储 HH:MM:SS 格式时长的文本字段"
              of-type="SingleLine.Text"
              usage="bound"
              required="true" />

    <resources>
      <code path="index.ts" order="1" />
      <platform-library name="React" version="16.14.0" />
      <platform-library name="Fluent" version="8.121.1" />
    </resources>

  </control>
</manifest>
```

> 平台库版本与 package.json 里的 react / @fluentui/react 保持一致。
> virtual 控件运行时用的是 D365 平台提供的 React/Fluent,bundle 里不打包它们,所以体积很小。

## 5. DurationInput/index.ts

```typescript
import { IInputs, IOutputs } from "./generated/ManifestTypes";
import * as React from "react";
import { HHMMSSInput, IHHMMSSInputProps } from "./HHMMSSInput";

export class DurationInput implements ComponentFramework.ReactControl<IInputs, IOutputs> {
    private notifyOutputChanged: () => void;
    private currentValue: string | null = null;

    public init(
        context: ComponentFramework.Context<IInputs>,
        notifyOutputChanged: () => void
    ): void {
        this.notifyOutputChanged = notifyOutputChanged;
        this.currentValue = context.parameters.thresholdValue.raw ?? null;
    }

    public updateView(context: ComponentFramework.Context<IInputs>): React.ReactElement {
        const props: IHHMMSSInputProps = {
            value: context.parameters.thresholdValue.raw ?? "",
            disabled: context.mode.isControlDisabled,
            onChange: (v: string | null) => {
                this.currentValue = v;
                this.notifyOutputChanged();   // 通知框架来读 getOutputs
            },
        };
        return React.createElement(HHMMSSInput, props);
    }

    public getOutputs(): IOutputs {
        // undefined = 清空字段
        return { thresholdValue: this.currentValue ?? undefined };
    }

    public destroy(): void {
        // virtual control 由框架卸载 React 树, 无需清理
    }
}
```

## 6. DurationInput/HHMMSSInput.tsx

```tsx
import * as React from "react";
import { Stack, TextField, Text, ITextField, ITextFieldStyles } from "@fluentui/react";

export interface IHHMMSSInputProps {
    /** 字段当前值, 期望 "HH:MM:SS" 或空 */
    value: string;
    disabled: boolean;
    /** 组合出完整值(或 null=清空)时回调 */
    onChange: (value: string | null) => void;
}

/** 把 "HH:MM:SS" 拆成三段, 非法/空 → 三个空串 */
function parse(v: string): [string, string, string] {
    const m = /^(\d{1,2}):([0-5]?\d):([0-5]?\d)$/.exec((v || "").trim());
    return m ? [m[1], m[2], m[3]] : ["", "", ""];
}

const pad = (s: string) => (s === "" ? "" : s.padStart(2, "0"));

/** 单框输入过滤: 只留数字, 最多2位, 分/秒钳制到59 */
function clean(raw: string, clamp59: boolean): string {
    let s = raw.replace(/\D/g, "").slice(0, 2);
    if (clamp59 && s.length > 0 && parseInt(s, 10) > 59) s = "59";
    return s;
}

const boxStyles: Partial<ITextFieldStyles> = {
    root: { width: 44 },
    field: { textAlign: "center" },
};

export const HHMMSSInput: React.FC<IHHMMSSInputProps> = (props) => {
    const [h, setH] = React.useState<string>("");
    const [m, setM] = React.useState<string>("");
    const [s, setS] = React.useState<string>("");
    // 最近一次向外发出的值, 用于区分"外部更新"和"自己发出的回流"
    const lastEmitted = React.useRef<string | null>(null);

    // Fluent 公开 API: ITextField 带 focus(), componentRef 直接挂
    const mRef = React.useRef<ITextField>(null);
    const sRef = React.useRef<ITextField>(null);

    // 外部值变化(表单加载/脚本改值)时同步到三框
    React.useEffect(() => {
        const incoming = (props.value || "").trim();
        if (incoming === (lastEmitted.current ?? "")) return; // 自己发的回流, 忽略
        const [ph, pm, ps] = parse(incoming);
        setH(ph); setM(pm); setS(ps);
        lastEmitted.current = incoming === "" ? null : incoming;
    }, [props.value]);

    /** 任一框变化后组合值发给PCF: 全空→null, 否则空框按"00"补齐 */
    const emit = (nh: string, nm: string, ns: string) => {
        let out: string | null;
        if (nh === "" && nm === "" && ns === "") {
            out = null;
        } else {
            out = `${pad(nh) || "00"}:${pad(nm) || "00"}:${pad(ns) || "00"}`;
        }
        lastEmitted.current = out;
        props.onChange(out);
    };

    const onBox =
        (setter: (v: string) => void, which: "h" | "m" | "s") =>
        (_: unknown, raw?: string) => {
            const v = clean(raw ?? "", which !== "h");
            setter(v);
            const nh = which === "h" ? v : h;
            const nm = which === "m" ? v : m;
            const ns = which === "s" ? v : s;
            emit(nh, nm, ns);
            // 敲满2位自动跳下一框
            if (v.length === 2) {
                if (which === "h") mRef.current?.focus();
                if (which === "m") sRef.current?.focus();
            }
        };

    // 失焦时把显示值补零(存储值在 emit 时已补, 这里只为显示整齐)
    const padOnBlur = (val: string, setter: (v: string) => void) => () => {
        if (val !== "") setter(pad(val));
    };

    const sep = <Text styles={{ root: { alignSelf: "center", fontWeight: 600 } }}>:</Text>;

    return (
        <Stack horizontal tokens={{ childrenGap: 4 }} verticalAlign="center">
            <TextField
                ariaLabel="小时"
                placeholder="HH"
                value={h}
                disabled={props.disabled}
                onChange={onBox(setH, "h")}
                onBlur={padOnBlur(h, setH)}
                styles={boxStyles}
                inputMode="numeric"
            />
            {sep}
            <TextField
                ariaLabel="分钟"
                placeholder="MM"
                value={m}
                disabled={props.disabled}
                onChange={onBox(setM, "m")}
                onBlur={padOnBlur(m, setM)}
                styles={boxStyles}
                inputMode="numeric"
                componentRef={mRef}
            />
            {sep}
            <TextField
                ariaLabel="秒"
                placeholder="SS"
                value={s}
                disabled={props.disabled}
                onChange={onBox(setS, "s")}
                onBlur={padOnBlur(s, setS)}
                styles={boxStyles}
                inputMode="numeric"
                componentRef={sRef}
            />
        </Stack>
    );
};
```

---

## 7. 构建命令

```bash
cd DurationInput          # 工程根目录
npm install               # 第一次, 装 pcf-scripts 等
npm run build             # 编译, 自动生成 DurationInput/generated/ManifestTypes.d.ts
npm start                 # (可选) test harness 本地调试, 浏览器自动打开
```

test harness 验证清单:
- 属性面板给 thresholdValue 填 `00:22:05` → 三框显示 00 / 22 / 05
- 分钟框输 67 → 自动钳到 59
- 敲满两位自动跳下一框
- 三框全清空 → 输出 null

生产构建:

```bash
npm run build -- --buildMode production
```

## 8. 产物与打包(按你们TagPicker同样流程)

构建产物在:

```
out/controls/DurationInput/
├── bundle.js
└── ControlManifest.xml
```

放进你们 solution 工程的 `Controls/AIA.DurationInput/` 目录,
customizations.xml 里登记 CustomControl 节点(照抄 TagPicker 那个控件的
节点改名字即可: 控件全名为 `AIA.DurationInput`),打zip导入,发布。

## 9. 挂表单

表单编辑器 → 选中 `demo_threshold` 字段 → 组件 → 添加
**Duration Input (HH:MM:SS)** → 勾选 Web/Phone/Tablet → 保存并发布。

---

## 常见坑速查

| 症状 | 原因/处理 |
|---|---|
| build 报找不到 `./generated/ManifestTypes` | 正常顺序是 build 自动先生成它; 若仍报错跑 `npm run refreshTypes` |
| npm install 慢/失败 | 公司代理: `npm config set registry` / proxy 先配好 |
| 运行时报 React/Fluent 库加载错误 | manifest platform-library 版本与环境不符, 试改回 `16.8.6` / `8.29.0` 这对旧版本 |
| 表单上控件不出现 | 导入后没发布; 或 customizations.xml 的 CustomControl 名字与 manifest 的 namespace.constructor 不一致 |
| TS 对 componentRef 报类型错 | 确认 import 里带了 `ITextField`; 实在不行删掉两个 componentRef 行(只损失自动跳格) |

## v2 待加清单

- ↑↓ 键微调数值
- 粘贴 "00:22:05" 到任意框自动拆三框
- 只读态渲染为纯文本而非禁用输入框
- HH 支持 3 位(改 clean() 的 slice 和 parse 的正则)
