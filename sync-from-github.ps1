# ============================================================
# sync-from-github.ps1
# Vigila main en GitHub, baja los cambios y los refleja en Studio:
#   - cambios .luau -> Script Sync los aplica en vivo
#   - cambios en build.lua / .rbxl -> cierra Studio, ejecuta build.lua y
#     vuelve a abrir el place (Script Sync se reconecta solo)
# Uso: powershell -ExecutionPolicy Bypass -File sync-from-github.ps1
# ============================================================
param(
    [int]$IntervalSeconds = 30,
    [int]$CloseTimeoutSeconds = 45,
    [switch]$DiscardLocal,
    [switch]$NoStudioRestart
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $MyInvocation.MyCommand.Definition
$place = Join-Path $repo "Place1.rbxl"
$lock = Join-Path $repo "Place1.rbxl.lock"
Set-Location $repo

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class BobuxWin32 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@

function Log([string]$message) {
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $message)
}

function Get-StudioExe {
    param([int]$ProcessIdFromLock = 0)
    if ($ProcessIdFromLock -gt 0) {
        $proc = Get-Process -Id $ProcessIdFromLock -ErrorAction SilentlyContinue
        if ($proc -and $proc.ProcessName -eq "RobloxStudioBeta" -and $proc.Path) {
            return $proc.Path
        }
    }
    $versions = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
    if (Test-Path $versions) {
        Get-ChildItem -Path $versions -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            ForEach-Object { Join-Path $_.FullName "RobloxStudioBeta.exe" } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1
    }
}

function Close-StudioGracefully {
    if (-not (Test-Path $lock)) { return $true }

    $lockPid = 0
    if (-not [int]::TryParse((Get-Content $lock -TotalCount 1).Trim(), [ref]$lockPid)) {
        Remove-Item $lock -Force -ErrorAction SilentlyContinue
        return $true
    }

    $proc = Get-Process -Id $lockPid -ErrorAction SilentlyContinue
    if (-not $proc -or $proc.ProcessName -ne "RobloxStudioBeta") {
        Remove-Item $lock -Force -ErrorAction SilentlyContinue
        return $true
    }

    $script:StudioExe = Get-StudioExe -ProcessIdFromLock $lockPid
    Log ("Cerrando Studio (PID " + $lockPid + ") para regenerar el place...")
    # WM_CLOSE: Studio podra preguntar si guardar. No se fuerza el cierre.
    [BobuxWin32]::PostMessage($proc.MainWindowHandle, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null

    for ($i = 0; $i -lt $CloseTimeoutSeconds; $i++) {
        Start-Sleep -Seconds 1
        if (-not (Test-Path $lock)) {
            Log "Studio cerrado."
            return $true
        }
    }
    Log "Studio sigue abierto (probablemente esperando a que guardes o descartes cambios)."
    Log "Se omite el build; al cerrar Studio se reintentara automaticamente."
    return $false
}

function Invoke-Build {
    $lune = Join-Path $repo ".tools\lune.exe"
    if (-not (Test-Path $lune)) {
        Log "ERROR: no esta .tools\lune.exe; no puedo regenerar el place."
        return $false
    }
    Log "Ejecutando build.lua..."
    Push-Location $repo
    try {
        & $lune run build.lua
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    if ($code -ne 0) {
        Log "ERROR: build.lua fallo (codigo $code)."
        return $false
    }
    Log "Place regenerado: Place1.rbxl y BobuxClicker.rbxl."
    return $true
}

function Open-Studio {
    param([string]$ExePath)
    if ($NoStudioRestart) { return }
    if (-not $ExePath) { $ExePath = Get-StudioExe }
    if (-not $ExePath) {
        Log "No encontre RobloxStudioBeta.exe; abre Place1.rbxl manualmente."
        return
    }
    Log "Reabriendo Studio con el place actualizado..."
    Start-Process -FilePath $ExePath -ArgumentList ('"' + $place + '"') | Out-Null
}

$script:StudioExe = $null

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

                $needsBuild = @($changed | Where-Object {
                    $_ -match '(^|/)(build\.lua|build\.bat|.*\.rbxlx?)$'
                })

                if ($needsBuild.Count -gt 0) {
                    if (Close-StudioGracefully) {
                        if (Invoke-Build) {
                            Open-Studio -ExePath $script:StudioExe
                            Log "Listo: los cambios del build ya estan en Studio."
                        }
                    }
                }
                else {
                    Log "Cambios de codigo: Script Sync los aplica solo en Studio."
                }
            }
        }
    }
    catch {
        Log ("ERROR: " + $_.Exception.Message)
    }
    Start-Sleep -Seconds $IntervalSeconds
}
