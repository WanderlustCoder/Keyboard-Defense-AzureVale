const path = require("node:path");

/** @type {import("eslint").Linter.Config} */
module.exports = {
  root: true,
  env: {
    browser: true,
    es2022: true,
    node: true
  },
  ignorePatterns: [
    "dist/",
    "dist-cjs/",
    "node_modules/",
    "artifacts/",
    "baselines/",
    "monitor-artifacts/",
    "smoke-artifacts/",
    "*.d.ts"
  ],
  overrides: [
    {
      files: ["src/**/*.ts", "types/**/*.ts", "types/**/*.d.ts"],
      parser: "@typescript-eslint/parser",
      parserOptions: {
        project: path.join(__dirname, "tsconfig.json"),
        tsconfigRootDir: __dirname,
        sourceType: "module",
        ecmaVersion: 2022
      },
      plugins: ["@typescript-eslint"],
      extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended", "prettier"],
      rules: {
        "@typescript-eslint/ban-ts-comment": [
          "warn",
          { "ts-ignore": "allow-with-description" }
        ],
        "@typescript-eslint/consistent-type-imports": [
          "warn",
          { prefer: "type-imports", fixStyle: "inline-type-imports" }
        ],
        "@typescript-eslint/no-misused-promises": [
          "error",
          { checksVoidReturn: { attributes: false } }
        ],
        "no-console": "off"
      }
    },
    {
      files: ["scripts/**/*.mjs", "tests/**/*.js"],
      env: {
        node: true,
        es2022: true
      },
      parserOptions: {
        sourceType: "module",
        ecmaVersion: 2022
      },
      extends: ["eslint:recommended", "prettier"],
      rules: {
        "no-console": "off"
      }
    }
  ]
};
