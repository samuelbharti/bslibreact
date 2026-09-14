// Deliberately narrow. Prettier already owns formatting and tsc already
// owns types, so the only rules here are the ones neither of those can
// catch: React's hook rules, which matter because this package is almost
// entirely hooks and components, and no-console.
//
// Both were already being disabled by name in the source before ESLint
// existed (useBoundScope.ts and usePageBody.ts each suppress
// exhaustive-deps for a documented reason, parity.test.ts suppresses
// no-console twice), so those comments described a checker that was not
// running. This makes them mean something.
import reactHooks from "eslint-plugin-react-hooks";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: [
      "dist/**",
      "dist-npm/**",
      "docs/**",
      "node_modules/**",
      "coverage/**",
      "*.config.js",
      "*.config.ts",
    ],
  },
  {
    files: ["src/**/*.{ts,tsx}", "tests/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
    plugins: { "react-hooks": reactHooks },
    rules: {
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "error",
      "no-console": "error",
    },
  },
);
