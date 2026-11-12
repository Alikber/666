# rebuild-ru.ps1 - applies the Russian UI to DeepAI Code (and re-applies it after an app update).
# Run with DeepAI Code fully CLOSED. The dictionary is dict\ru-dict.tsv in this repository.
#   powershell -ExecutionPolicy Bypass -File .\scripts\rebuild-ru.ps1
$ErrorActionPreference = 'Stop'
$utf8    = New-Object System.Text.UTF8Encoding($false)
$w       = Join-Path $HOME 'deepai-work'
$install = Join-Path $env:LOCALAPPDATA 'Programs\deepai-code-desktop'
$r       = Join-Path $install 'resources'
$asar    = Join-Path $r 'server.asar'
$dictFile = Join-Path $PSScriptRoot '..\dict\ru-dict.tsv'
if (-not (Test-Path $dictFile)) { $dictFile = Join-Path $w 'ru-dict.tsv' }
if (-not (Test-Path $w)) { New-Item -ItemType Directory $w | Out-Null }
$src     = Join-Path $w 'server-new'
$assets  = Join-Path $src 'apps\server\dist\client\assets'
$outAsar = Join-Path $w 'server-new-ru.asar'

if (-not (Test-Path $asar))     { throw "Not found: $asar" }
if (-not (Test-Path $dictFile)) { throw "Not found: $dictFile" }

$running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$install*" }
if ($running) { throw 'DeepAI Code is still running. Close it completely (also the tray icon) and run again.' }

Write-Host '1/6 Extracting the current server.asar ...'
if (Test-Path $src) { Remove-Item $src -Recurse -Force }
npx --yes @electron/asar extract $asar $src
if (-not (Test-Path $assets)) { throw "Client folder not found: $assets (the app layout changed)" }

Write-Host '2/6 Reading the list of files stored outside the archive ...'
$unpackLines = npx --yes @electron/asar list --is-pack $asar | Select-String '^unpack' | ForEach-Object { $_.Line }
$pat = '{' + (($unpackLines | ForEach-Object { '**/' + (($_ -replace '^unpack : \\','') -replace '\\','/') }) -join ',') + '}'

Write-Host '3/6 Applying the Russian dictionary ...'
$dict = @{}
foreach ($line in [IO.File]::ReadAllLines($dictFile, $utf8)) {
    $p = $line.Split("`t")
    if ($p.Count -eq 2 -and $p[0].Length -gt 0) { $dict[$p[0]] = $p[1] }
}
Write-Host ("    dictionary entries: " + $dict.get_Count())
$rx = [regex]'(?<pre>children:\[?(?:[\w$]+,)*|placeholder:|title:|label:|description:|text:|aria-label:|alt:|tooltip:|message:|header:|heading:|subtitle:)(?<q>[`"])(?<s>[A-Za-z](?:(?!\k<q>)[^\r\n]){2,260})\k<q>'
$global:cnt = 0
$evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
    param($m)
    $s = $m.Groups['s'].Value
    if ($dict.ContainsKey($s)) {
        $global:cnt++
        $q = $m.Groups['q'].Value
        return $m.Groups['pre'].Value + $q + $dict[$s] + $q
    }
    return $m.Value
}
$files = 0
Get-ChildItem $assets -Filter *.js | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName, $utf8)
    $before = $global:cnt
    $new = $rx.Replace($text, $evaluator)
    if ($global:cnt -gt $before) { [IO.File]::WriteAllText($_.FullName, $new, $utf8); $files++ }
}
Write-Host "    replacements: $($global:cnt) in $files files"
if ($global:cnt -lt 100) { throw 'Too few replacements - the app changed too much. Nothing was modified.' }

Write-Host '4/6 Packing the new archive (a few minutes) ...'
if (Test-Path $outAsar) { Remove-Item $outAsar -Force }
npx --yes @electron/asar pack $src $outAsar --unpack $pat

Write-Host '5/6 Checking that the outside-the-archive files are identical ...'
$newLines = npx --yes @electron/asar list --is-pack $outAsar | Select-String '^unpack' | ForEach-Object { $_.Line }
$diff = Compare-Object $unpackLines $newLines
if ($diff) { $diff | Out-Host; throw 'File lists differ. The installed app was NOT changed.' }

Write-Host '6/6 Replacing server.asar (a backup is kept) ...'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $w "server.asar.backup-$stamp"
Copy-Item $asar $backup -Force
Copy-Item $outAsar $asar -Force
Write-Host "Done. Backup of the previous file: $backup"
Write-Host "To undo: Copy-Item '$backup' '$asar' -Force   (with the app closed)"
