[CmdletBinding()]
param()

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

$targetText = Require-EnvironmentValue "HBT_TLS_BASE_URL"
$authorizationId = Require-EnvironmentValue "HBT_SECURITY_AUTHORIZATION_ID"
$confirmation = Require-EnvironmentValue "HBT_TLS_CONFIRM"
if ($confirmation -cne "I_CONFIRM_AUTHORIZED_TLS_STAGING_SCAN") {
    throw "HBT_TLS_CONFIRM must exactly equal I_CONFIRM_AUTHORIZED_TLS_STAGING_SCAN."
}

$target = $null
if (-not [Uri]::TryCreate($targetText, [UriKind]::Absolute, [ref]$target) -or
    $target.Scheme -cne "https" -or $target.IsLoopback -or
    $target.Query -or $target.Fragment -or $target.UserInfo) {
    throw "Use an absolute, non-loopback HTTPS staging URL without credentials, query or fragment."
}

$productionHosts = @()
if (-not [string]::IsNullOrWhiteSpace($env:HBT_PRODUCTION_HOSTS)) {
    $productionHosts = $env:HBT_PRODUCTION_HOSTS.Split(",") |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object { $_ }
}
if ($productionHosts -contains $target.Host.ToLowerInvariant()) {
    throw "The target matches HBT_PRODUCTION_HOSTS. This runner is staging-only."
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is required for the testssl.sh scan."
}

$evidenceRoot = Join-Path $PSScriptRoot "..\security\evidence"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidenceDirectory = Join-Path $evidenceRoot "tls-headers-$timestamp"
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
$mountPath = (Resolve-Path $evidenceDirectory).Path

[ordered]@{
    authorization_id = $authorizationId
    target = $target.GetLeftPart([UriPartial]::Authority)
    started_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    image = "ghcr.io/testssl/testssl.sh:3.2.3"
} | ConvertTo-Json | Set-Content `
    -LiteralPath (Join-Path $evidenceDirectory "authorization-metadata.json") `
    -Encoding utf8

try {
    $response = Invoke-WebRequest -Uri $targetText -Method Head `
        -MaximumRedirection 0 -TimeoutSec 30 -UseBasicParsing
}
catch {
    if ($null -eq $_.Exception.Response) {
        throw
    }
    $response = $_.Exception.Response
}
$requiredHeaders = @(
    "Strict-Transport-Security",
    "Content-Security-Policy",
    "X-Content-Type-Options",
    "Referrer-Policy",
    "Permissions-Policy"
)
$headerResults = foreach ($name in $requiredHeaders) {
    [ordered]@{
        name = $name
        present = $null -ne $response.Headers[$name]
        value = if ($null -ne $response.Headers[$name]) {
            ($response.Headers[$name] -join ", ")
        } else { $null }
    }
}
$hasFrameDefence = (
    $null -ne $response.Headers["Content-Security-Policy"] -or
    $null -ne $response.Headers["X-Frame-Options"]
)
[ordered]@{
    status_code = [int]$response.StatusCode
    checked_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    required = $headerResults
    has_frame_defence = $hasFrameDefence
} | ConvertTo-Json -Depth 5 | Set-Content `
    -LiteralPath (Join-Path $evidenceDirectory "security-headers.json") `
    -Encoding utf8

& docker run --rm `
    --volume "${mountPath}:/data/:rw" `
    ghcr.io/testssl/testssl.sh:3.2.3 `
    --warnings batch `
    --severity LOW `
    --jsonfile-pretty /data/testssl.json `
    --htmlfile /data/testssl.html `
    ($target.GetLeftPart([UriPartial]::Authority)) 2>&1 |
    Tee-Object -FilePath (Join-Path $evidenceDirectory "console.log")
$exitCode = $LASTEXITCODE

$missingHeaders = @($headerResults | Where-Object { -not $_.present })
[ordered]@{
    completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    testssl_exit_code = $exitCode
    missing_required_headers = @($missingHeaders.name)
    has_frame_defence = $hasFrameDefence
} | ConvertTo-Json | Set-Content `
    -LiteralPath (Join-Path $evidenceDirectory "completion.json") `
    -Encoding utf8

if ($exitCode -ne 0 -or $missingHeaders.Count -gt 0 -or -not $hasFrameDefence) {
    throw "TLS/header gate failed. Review evidence in $mountPath."
}
Write-Host "TLS and header gate passed. Review the complete reports before release."
