[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $RepoRoot

$AppId = "{8F2B6B8E-6B9B-4B0E-9B8E-7B6C2E7B6B8E}"
$IssPath = Join-Path $RepoRoot "installer\iptv_jotac.iss"
$SetupExe = Join-Path $RepoRoot "installer\Output\IPTV_Jotac_Setup.exe"

function Find-Iscc {
    $candidates = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe")
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    $onPath = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    return $null
}

function Get-ExistingInstall {
    $uninstallKeys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppId`_is1",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$AppId`_is1",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppId`_is1"
    )
    foreach ($key in $uninstallKeys) {
        if (Test-Path $key) {
            $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($props -and $props.UninstallString) {
                return $props.UninstallString
            }
        }
    }
    return $null
}

Write-Host "==> Verificando pre-requisitos..." -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao encontrado no PATH. Instale em https://docs.flutter.dev/get-started/install"
}

$iscc = Find-Iscc
if (-not $iscc) {
    throw "Inno Setup (ISCC.exe) nao encontrado. Instale em https://jrsoftware.org/isdl.php e rode novamente."
}
Write-Host "Inno Setup encontrado em: $iscc"

if (-not $SkipBuild) {
    Write-Host "==> Gerando build de release (flutter build windows --release)..." -ForegroundColor Cyan
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows --release falhou (codigo $LASTEXITCODE)." }
} else {
    Write-Host "==> Pulando build (SkipBuild)." -ForegroundColor Yellow
}

Write-Host "==> Procurando instalacao anterior..." -ForegroundColor Cyan
$uninstallString = Get-ExistingInstall

if ($uninstallString) {
    Write-Host "Instalacao anterior encontrada. Desinstalando antes de prosseguir..." -ForegroundColor Yellow

    $uninstallExe = $uninstallString.Trim('"')
    if (Test-Path $uninstallExe) {
        Start-Process -FilePath $uninstallExe -ArgumentList "/VERYSILENT", "/NORESTART", "/SUPPRESSMSGBOXES" -Wait
        Write-Host "Versao anterior desinstalada." -ForegroundColor Green
    } else {
        Write-Host "Aviso: caminho do desinstalador nao encontrado ($uninstallExe). Prosseguindo mesmo assim." -ForegroundColor Yellow
    }
} else {
    Write-Host "Nenhuma instalacao anterior encontrada." -ForegroundColor Green
}

Write-Host "==> Compilando instalador com Inno Setup..." -ForegroundColor Cyan
& $iscc $IssPath
if ($LASTEXITCODE -ne 0) { throw "ISCC.exe falhou (codigo $LASTEXITCODE)." }

if (-not (Test-Path $SetupExe)) {
    throw "Instalador nao foi gerado em: $SetupExe"
}

Write-Host "==> Instalando IPTV Jotac..." -ForegroundColor Cyan
if ($Silent) {
    Start-Process -FilePath $SetupExe -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
    Write-Host "Instalacao concluida (silenciosa)." -ForegroundColor Green
} else {
    Start-Process -FilePath $SetupExe -Wait
    Write-Host "Assistente de instalacao finalizado." -ForegroundColor Green
}
