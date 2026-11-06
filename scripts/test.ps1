[CmdletBinding()]
param(
    [string]$Suite = 'all'
)

$ErrorActionPreference = 'Stop'
try {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $toolchain = Get-Content -LiteralPath (Join-Path $projectRoot 'tools/toolchain.json') -Raw | ConvertFrom-Json
    $godot = Join-Path $projectRoot $toolchain.console_executable
    if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) {
        throw "Godot bulunamadı: $godot. README.md içindeki kurulum adımlarını izleyin."
    }
    $actualVersion = (& $godot --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $actualVersion -ne $toolchain.version_output) {
        throw "Godot sürümü eşleşmiyor. Beklenen: $($toolchain.version_output); bulunan: $actualVersion"
    }
    & $godot --headless --path (Join-Path $projectRoot 'game') --script res://tests/run_tests.gd -- "--suite=$Suite"
    exit $LASTEXITCODE
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
