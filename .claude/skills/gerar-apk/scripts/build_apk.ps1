[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$SplitPerAbi,
    [switch]$NoBump,
    [switch]$BumpMinor,
    [switch]$BumpMajor
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
Set-Location $RepoRoot

$PubspecPath = Join-Path $RepoRoot "pubspec.yaml"
$OutputDir = Join-Path $RepoRoot "build\app\outputs\flutter-apk"
$DownloadsDir = Join-Path $env:USERPROFILE "Downloads"

# Versionamento semantico padronizado: version = MAJOR.MINOR.PATCH+BUILD,
# onde MAJOR.MINOR.PATCH sempre reflete o PATCH igual ao numero de BUILD
# (ex.: 1.0.3+3). android/app/build.gradle.kts le versionName/versionCode
# direto do pubspec.yaml (flutter.versionName / flutter.versionCode) -- nao
# tem versao hardcoded em outro lugar. Por padrao, cada execucao desta
# skill incrementa PATCH+BUILD em 1; use -NoBump para re-gerar o apk da
# mesma versao (ex.: so trocou algo no build.gradle, sem mudar o codigo
# Dart), ou -BumpMinor/-BumpMajor para uma mudanca maior de verdade.
function Get-PubspecVersionParts {
    $line = Select-String -Path $PubspecPath -Pattern '^version:\s*(\S+)' | Select-Object -First 1
    if (-not $line) { throw "Nao encontrei a linha 'version:' em $PubspecPath." }
    $raw = $line.Matches[0].Groups[1].Value
    $semverPart, $buildPart = $raw -split '\+'
    $major, $minor, $patch = $semverPart -split '\.' | ForEach-Object { [int]$_ }
    $build = if ($buildPart) { [int]$buildPart } else { 0 }
    return [PSCustomObject]@{ Major = $major; Minor = $minor; Patch = $patch; Build = $build }
}

function Set-PubspecVersion([PSCustomObject]$v) {
    $newVersionLine = "version: $($v.Major).$($v.Minor).$($v.Patch)+$($v.Build)"
    $content = Get-Content $PubspecPath -Raw
    $content = $content -replace '(?m)^version:\s*\S+', $newVersionLine
    Set-Content -Path $PubspecPath -Value $content -NoNewline
    return "$($v.Major).$($v.Minor).$($v.Patch)"
}

$current = Get-PubspecVersionParts
if ($NoBump) {
    $version = "$($current.Major).$($current.Minor).$($current.Patch)"
    Write-Host "==> Mantendo versao atual (NoBump): $version+$($current.Build)" -ForegroundColor Yellow
} elseif ($BumpMajor) {
    $current.Major++; $current.Minor = 0; $current.Patch = 0; $current.Build++
    $version = Set-PubspecVersion $current
    Write-Host "==> Versao (major bump): $version+$($current.Build)" -ForegroundColor Cyan
} elseif ($BumpMinor) {
    $current.Minor++; $current.Patch = 0; $current.Build++
    $version = Set-PubspecVersion $current
    Write-Host "==> Versao (minor bump): $version+$($current.Build)" -ForegroundColor Cyan
} else {
    $current.Patch++; $current.Build++
    $version = Set-PubspecVersion $current
    Write-Host "==> Versao (patch bump): $version+$($current.Build)" -ForegroundColor Cyan
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
