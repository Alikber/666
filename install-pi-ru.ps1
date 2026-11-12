# install-pi-ru.ps1 - copies the Russian files into the pi-di18n package (console version of pi).
# Prerequisite:  pi install npm:pi-di18n     (then run this script, restart pi, type /lang ru)
$ErrorActionPreference = 'Stop'
$p = Join-Path $HOME '.pi\agent\npm\node_modules\pi-di18n'
if (-not (Test-Path $p)) { throw "pi-di18n not found: $p  (run: pi install npm:pi-di18n)" }
Copy-Item (Join-Path $PSScriptRoot 'locales\ru.json') (Join-Path $p 'locales\ru.json') -Force
Copy-Item (Join-Path $PSScriptRoot 'core-hacks-locales\ru.json') (Join-Path $p 'src\core-hacks-locales\ru.json') -Force
Write-Host 'Done. Restart pi and type: /lang ru'
