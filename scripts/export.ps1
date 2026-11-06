[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
try {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $toolchain = Get-Content -LiteralPath (Join-Path $projectRoot 'tools/toolchain.json') -Raw | ConvertFrom-Json
    $godot = Join-Path $projectRoot $toolchain.console_executable
    if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) { throw "Godot bulunamadı: $godot. README.md kurulumunu izleyin." }
    $actualVersion = (& $godot --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $actualVersion -ne $toolchain.version_output) { throw "Godot sürümü eşleşmiyor: $actualVersion" }
    $templates = Join-Path $projectRoot 'tools/godot/templates'
    $versionPath = Join-Path $templates 'version.txt'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or (Get-Content -LiteralPath $versionPath -Raw).Trim() -ne $toolchain.export_templates.version) { throw 'Eşleşen export şablonları yok. README.md şablon kurulumunu izleyin.' }
    foreach ($name in @('windows_debug_x86_64.exe','windows_release_x86_64.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $templates $name) -PathType Leaf)) { throw "Export şablonu eksik: $name" }
    }
    $outputDir = Join-Path $projectRoot 'build/windows'
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    $game = Join-Path $projectRoot 'game'
    & $godot --headless --path $game --editor --import
    if ($LASTEXITCODE -ne 0) { throw "Godot import başarısız: $LASTEXITCODE" }
    $output = Join-Path $outputDir 'SehirHayat.exe'
    & $godot --headless --path $game --export-release 'Windows Desktop' $output
    if ($LASTEXITCODE -ne 0) { throw "Windows export başarısız: $LASTEXITCODE" }
    foreach ($path in @($output, (Join-Path $outputDir 'SehirHayat.pck'))) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) { throw "Export çıktısı eksik veya boş: $path" }
    }
    Write-Output "Windows paketi hazır: $output"
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
