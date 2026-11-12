# deepai-code-ru — Russian UI for DeepAI Code

Unofficial Russian localization for the **DeepAI Code** desktop app (Windows). Not affiliated with the DeepAI Code developers. The repo ships only a translation dictionary and scripts; it contains no application files.

The app has no language setting, so the script extracts `server.asar`, replaces English UI strings using `dict/ru-dict.tsv` (~2500 entries), repacks it with the same unpacked-file list, verifies it, backs up the original and swaps it in.

## Usage

Requirements: Windows 10/11, PowerShell 5.1, Node.js (for `npx`).

1. Close DeepAI Code completely (also the tray icon).
2. Run: `powershell -ExecutionPolicy Bypass -File .\scripts\rebuild-ru.ps1`
3. Start the app. To undo, copy the printed `server.asar.backup-*` file back over `resources\server.asar` (app closed).

Auto-updates replace `server.asar`: disable them in Settings and re-run the script after each update.

Some strings stay in English (they are written in code contexts the script does not match yet). Pull requests with dictionary additions are welcome (format: `English<TAB>Russian`, UTF-8; no backticks, `${`, backslashes or straight double quotes in the Russian text).

Use at your own risk and check the app's license terms. MIT licensed.
