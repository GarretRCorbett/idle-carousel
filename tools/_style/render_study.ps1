# Rebuild both palettes and all renders, then leave recommended Purple Garden applied.
# Run from this worktree: powershell -File tools/_style/render_study.ps1
$ErrorActionPreference = 'Stop'
$studyRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if ((Get-Location).Path -ne $studyRoot) { throw 'Run from the ic-codex worktree root.' }
if ((git branch --show-current) -ne 'codex/tier-outlines-palette') { throw 'Wrong branch for this study.' }
if (-not (Test-Path -LiteralPath $env:GODOT -PathType Leaf)) { throw 'GODOT must name the executable.' }
New-Item -ItemType Directory -Force -Path '.godot' | Out-Null

function Invoke-StudyGodot([string] $Arguments, [string] $LogName) {
    $run = Start-Process -FilePath $env:GODOT -ArgumentList $Arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput ".godot/$LogName.log" -RedirectStandardError ".godot/$LogName.errors.log"
    $errors = Get-Content ".godot/$LogName.errors.log" -Raw
    if ($run.ExitCode -ne 0 -or $errors -match 'SCRIPT ERROR|ERROR:') { throw "Godot failed: $LogName ($errors)" }
}

Invoke-StudyGodot '--headless --path . --import' 'style_import'
try {
    Invoke-StudyGodot '--headless --path . -s res://tools/build_ui_theme.gd -- purple_garden' 'style_build_a'
    Invoke-StudyGodot '--audio-driver Dummy --path . --fixed-fps 10 --quit-after 200 tools/_style/StyleStudy.tscn -- purple_garden sheets' 'style_render_a'
    Invoke-StudyGodot '--headless --path . -s res://tools/build_ui_theme.gd -- gilded_plum' 'style_build_b'
    Invoke-StudyGodot '--audio-driver Dummy --path . --fixed-fps 10 --quit-after 200 tools/_style/StyleStudy.tscn -- gilded_plum compare' 'style_render_b'
} finally {
    Invoke-StudyGodot '--headless --path . -s res://tools/build_ui_theme.gd -- purple_garden' 'style_restore_a'
}
& tools/check.bat
if ($LASTEXITCODE -ne 0) { throw 'Project check failed.' }
