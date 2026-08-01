[CmdletBinding()]
param(
    [ValidateSet("baseline", "api-active", "full-active")]
    [string]$Mode = "baseline",
    [int]$Minutes = 10
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Require-EnvironmentValue {
    param([string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Required environment variable '$Name' is missing."
    }
    return $value
}

$targetText = Require-EnvironmentValue "HBT_DAST_BASE_URL"
$confirmation = Require-EnvironmentValue "HBT_DAST_CONFIRM"
$authorizationId = Require-EnvironmentValue "HBT_SECURITY_AUTHORIZATION_ID"

if ($confirmation -cne "I_CONFIRM_AUTHORIZED_DISPOSABLE_STAGING") {
    throw "HBT_DAST_CONFIRM must exactly equal I_CONFIRM_AUTHORIZED_DISPOSABLE_STAGING."
}

$target = $null
if (-not [Uri]::TryCreate($targetText, [UriKind]::Absolute, [ref]$target)) {
    throw "HBT_DAST_BASE_URL must be an absolute URL."
}
if ($target.Scheme -cne "https") {
    throw "Only HTTPS staging targets are allowed."
}
if ($target.IsLoopback -or $target.Host -in @("localhost", "127.0.0.1", "::1")) {
    throw "Use an isolated, remotely reachable HTTPS staging target."
}
if ($target.Query -or $target.Fragment -or $target.UserInfo) {
    throw "The target must not contain credentials, query parameters or a fragment."
}
if ($Minutes -lt 1 -or $Minutes -gt 30) {
    throw "Minutes must be between 1 and 30."
}

$productionHosts = @()
if (-not [string]::IsNullOrWhiteSpace($env:HBT_PRODUCTION_HOSTS)) {
    $productionHosts = $env:HBT_PRODUCTION_HOSTS.Split(",") |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object { $_ }
}
if ($productionHosts -contains $target.Host.ToLowerInvariant()) {
    throw "The target matches HBT_PRODUCTION_HOSTS. DAST against production is prohibited."
}

if ($Mode -ne "baseline") {
    $activeConfirmation = Require-EnvironmentValue "HBT_DAST_ACTIVE_CONFIRM"
    if ($activeConfirmation -cne "I_CONFIRM_ACTIVE_ATTACKS_AND_DATA_RESET") {
        throw "Active scans require HBT_DAST_ACTIVE_CONFIRM=I_CONFIRM_ACTIVE_ATTACKS_AND_DATA_RESET."
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is required to run the pinned OWASP ZAP container."
}

$evidenceRoot = Join-Path $PSScriptRoot "..\security\evidence"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidenceDirectory = Join-Path $evidenceRoot "zap-$Mode-$timestamp"
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null

$metadata = [ordered]@{
    authorization_id = $authorizationId
    target = $target.GetLeftPart([UriPartial]::Authority)
    mode = $Mode
    started_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    operator = [Environment]::UserName
    max_minutes = $Minutes
    image = "ghcr.io/zaproxy/zaproxy:stable"
}
$metadata | ConvertTo-Json | Set-Content `
    -LiteralPath (Join-Path $evidenceDirectory "authorization-metadata.json") `
    -Encoding utf8

$mountPath = (Resolve-Path $evidenceDirectory).Path
$commonReports = @(
    "-r", "report.html",
    "-w", "report.md",
    "-x", "report.xml",
    "-J", "report.json",
    "-T", "$Minutes"
)

if ($Mode -eq "baseline") {
    $zapCommand = @(
        "zap-baseline.py",
        "-t", $targetText,
        "-m", "$Minutes",
        "-I"
    ) + $commonReports
}
elseif ($Mode -eq "full-active") {
    $zapCommand = @(
        "zap-full-scan.py",
        "-t", $targetText,
        "-m", "$Minutes",
        "-I"
    ) + $commonReports
}
else {
    $openApiUrl = Require-EnvironmentValue "HBT_DAST_OPENAPI_URL"
    $openApiUri = $null
    if (-not [Uri]::TryCreate($openApiUrl, [UriKind]::Absolute, [ref]$openApiUri) -or
        $openApiUri.Scheme -cne "https" -or
        $openApiUri.Host -cne $target.Host) {
        throw "HBT_DAST_OPENAPI_URL must be HTTPS and use the same staging host."
    }
    $zapCommand = @(
        "zap-api-scan.py",
        "-t", $openApiUrl,
        "-f", "openapi",
        "-I"
    ) + $commonReports
}

Write-Host "Authorization: $authorizationId"
Write-Host "Running OWASP ZAP mode '$Mode' against isolated staging host '$($target.Host)'."
Write-Host "Evidence: $mountPath"

& docker run --rm `
    --volume "${mountPath}:/zap/wrk/:rw" `
    ghcr.io/zaproxy/zaproxy:stable `
    @zapCommand 2>&1 |
    Tee-Object -FilePath (Join-Path $evidenceDirectory "console.log")
$exitCode = $LASTEXITCODE

$completion = [ordered]@{
    completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    zap_exit_code = $exitCode
    interpretation = switch ($exitCode) {
        0 { "success" }
        1 { "at_least_one_fail" }
        2 { "warnings_only" }
        default { "execution_error" }
    }
}
$completion | ConvertTo-Json | Set-Content `
    -LiteralPath (Join-Path $evidenceDirectory "completion.json") `
    -Encoding utf8

if ($exitCode -notin @(0, 2)) {
    throw "ZAP failed or reported a FAIL. Review evidence in $mountPath."
}
Write-Host "ZAP completed. Warnings remain findings to triage; they are not a security pass."

