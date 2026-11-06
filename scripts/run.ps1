[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
try {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $toolchain = Get-Content -LiteralPath (Join-Path $projectRoot 'tools/toolchain.json') -Raw | ConvertFrom-Json
    $godot = Join-Path $projectRoot $toolchain.gui_executable
    $console = Join-Path $projectRoot $toolchain.console_executable
    foreach ($executable in @($godot, $console)) {
        if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
            throw "Godot bulunamadı: $executable. README.md içindeki kurulum adımlarını izleyin."
        }
    }
    $actualVersion = (& $console --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $actualVersion -ne $toolchain.version_output) {
        throw "Godot sürümü eşleşmiyor. Beklenen: $($toolchain.version_output); bulunan: $actualVersion"
    }
    $process = Start-Process -FilePath $godot -ArgumentList @('--path', ('"{0}"' -f (Join-Path $projectRoot 'game'))) -WindowStyle Normal -Wait -PassThru
    exit $process.ExitCode
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
