# Renders cv.ru.html / cv.en.html to PDF with headless Edge (or Chrome).
# Usage:  powershell -ExecutionPolicy Bypass -File cv\build.ps1
#         powershell -ExecutionPolicy Bypass -File cv\build.ps1 -Final   # writes the site's Qyedo_CV*.pdf
# Needs internet for Google Fonts; without it the PDF falls back to system fonts.
param([switch]$Final)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$root = Split-Path $here -Parent

$browser = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw 'Edge or Chrome not found' }

$targets = if ($Final) {
  @{ 'cv.ru.html' = Join-Path $root 'Qyedo_CV.pdf'; 'cv.en.html' = Join-Path $root 'Qyedo_CV_EN.pdf' }
} else {
  @{ 'cv.ru.html' = Join-Path $here 'Qyedo_CV_draft_RU.pdf'; 'cv.en.html' = Join-Path $here 'Qyedo_CV_draft_EN.pdf' }
}

foreach ($src in $targets.Keys) {
  $out = $targets[$src]
  $url = ([System.Uri](Join-Path $here $src)).AbsoluteUri
  $profile = Join-Path $env:TEMP ("cv-build-" + [guid]::NewGuid())
  if (Test-Path $out) { Remove-Item $out -Force }
  $argv = @('--headless=new', '--disable-gpu', '--no-first-run', "--user-data-dir=`"$profile`"",
            '--no-pdf-header-footer', '--virtual-time-budget=8000', "--print-to-pdf=`"$out`"", $url)
  # Start-Process keeps the browser's stderr noise from aborting the script under PowerShell 5.1
  Start-Process -FilePath $browser -ArgumentList $argv -Wait -WindowStyle Hidden
  Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
  if (-not (Test-Path $out)) { throw "PDF was not created: $out" }
  Write-Host "ok  $out"
}
