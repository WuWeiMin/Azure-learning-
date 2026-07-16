import powerApps from "@microsoft/eslint-plugin-power-apps";

export default [
    {
        files: ["**/*.ts", "**/*.tsx"],
        plugins: {
            "@microsoft/power-apps": powerApps,
        },
        rules: {
            ...powerApps.configs.recommended.rules,
        },
    },
];