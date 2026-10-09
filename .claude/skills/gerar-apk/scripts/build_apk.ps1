[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$SplitPerAbi
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $RepoRoot

$PubspecPath = Join-Path $RepoRoot "pubspec.yaml"
$OutputDir = Join-Path $RepoRoot "build\app\outputs\flutter-apk"
$DownloadsDir = Join-Path $env:USERPROFILE "Downloads"

function Get-AppVersion {
    $line = Select-String -Path $PubspecPath -Pattern '^version:\s*(\S+)' | Select-Object -First 1
    if (-not $line) { return "0.0.0" }
    $raw = $line.Matches[0].Groups[1].Value
    return ($raw -split '\+')[0]
}

if (-not $SkipBuild) {
    Write-Host "==> Gerando APK de release..." -ForegroundColor Cyan
    if ($SplitPerAbi) {
        flutter build apk --release --split-per-abi
    } else {
        flutter build apk --release
    }
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk falhou (codigo $LASTEXITCODE)." }
} else {
    Write-Host "==> Pulando build (SkipBuild)." -ForegroundColor Yellow
}

if (-not (Test-Path $OutputDir)) {
    throw "Pasta de saida nao encontrada: $OutputDir (rode sem -SkipBuild na primeira vez)."
}

if (-not (Test-Path $DownloadsDir)) {
    New-Item -ItemType Directory -Path $DownloadsDir -Force | Out-Null
}

$version = Get-AppVersion
Write-Host "==> Versao detectada: $version" -ForegroundColor Cyan

$apks = Get-ChildItem -Path $OutputDir -Filter "*.apk"
if ($apks.Count -eq 0) {
    throw "Nenhum .apk encontrado em $OutputDir."
}

foreach ($apk in $apks) {
    $abiSuffix = ""
    if ($apk.Name -match "app-(armeabi-v7a|arm64-v8a|x86_64|x86)-release\.apk") {
        $abiSuffix = "_$($Matches[1])"
    }
    $destName = "IPTV_Jotac_${version}${abiSuffix}.apk"
    $destPath = Join-Path $DownloadsDir $destName
    Copy-Item -Path $apk.FullName -Destination $destPath -Force
    $sizeMb = [math]::Round((Get-Item $destPath).Length / 1MB, 1)
    Write-Host "Copiado: $destPath ($sizeMb MB)" -ForegroundColor Green
}

Write-Host "==> Pronto. Envie o(s) arquivo(s) acima para o celular/Fire TV." -ForegroundColor Cyan
