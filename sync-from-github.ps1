# ============================================================
# sync-from-github.ps1
# Vigila la rama main de GitHub y baja los cambios a esta carpeta.
# Script Sync de Roblox Studio se encarga de reflejarlos en Studio.
# Uso: powershell -ExecutionPolicy Bypass -File sync-from-github.ps1
# ============================================================
param(
    [int]$IntervalSeconds = 30,
    [switch]$DiscardLocal
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $repo

function Log([string]$message) {
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $message)
}

Log "Bobux: GitHub (main) -> carpeta local -> Studio"
Log "Carpeta: $repo"
Log "Cada $IntervalSeconds s. Presiona Ctrl+C para detener."

while ($true) {
    try {
        git fetch origin main --quiet
        $head = (git rev-parse HEAD).Trim()
        $remote = (git rev-parse origin/main).Trim()

        if ($head -ne $remote) {
            $dirty = @(git status --porcelain)
            if ($dirty.Count -gt 0 -and -not $DiscardLocal) {
                Log "Hay cambios locales sin commitear; se omite el pull para no perderlos:"
                $dirty | ForEach-Object { Log ("  " + $_) }
                Log "Haz commit de esos cambios o ejecuta con -DiscardLocal."
            }
            else {
                $changed = @(git diff --name-only $head $remote)
                if ($dirty.Count -gt 0 -and $DiscardLocal) {
                    git reset --hard origin/main | Out-Null
                    Log "Descartados cambios locales (pediste -DiscardLocal)."
                }
                else {
                    git merge --ff-only origin/main | Out-Null
                }
                Log ("Actualizado a " + $remote.Substring(0, 7))
                $changed | ForEach-Object { Log ("  cambio: " + $_) }

                $needsRebuild = @($changed | Where-Object { $_ -match '(^|/)(build\.lua|build\.bat|.*\.rbxlx?)$' })
                if ($needsRebuild.Count -gt 0) {
                    Log "AVISO: cambio en build/place. Cierra Studio y ejecuta build.bat para regenerar Place1.rbxl."
                }
                else {
                    Log "Los cambios de codigo deberian aparecer solos en Studio (Script Sync)."
                }
            }
        }
    }
    catch {
        Log ("ERROR: " + $_.Exception.Message)
    }
    Start-Sleep -Seconds $IntervalSeconds
}
