$ErrorActionPreference = "Stop"

if (-not $env:HBT_FUZZ_BASE_URL) {
    throw "HBT_FUZZ_BASE_URL is required."
}
if ($env:HBT_FUZZ_CONFIRM -ne $env:HBT_FUZZ_BASE_URL) {
    throw "HBT_FUZZ_CONFIRM must exactly match HBT_FUZZ_BASE_URL."
}
if (-not $env:HBT_SECURITY_AUTHORIZATION_ID) {
    throw "Written authorization reference is required."
}
if ($env:HBT_FUZZ_BASE_URL -notmatch '^https://') {
    throw "Only an HTTPS authorized staging target is allowed."
}

$Backend = Join-Path $PSScriptRoot "..\backend"
$Schemathesis = Join-Path $Backend ".venv\Scripts\schemathesis.exe"
$ReportDir = Join-Path $Backend "security-evidence\schemathesis"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$Arguments = @(
    "run",
    (Join-Path $Backend "openapi.yaml"),
    "--url", $env:HBT_FUZZ_BASE_URL,
    "--phases", "examples,coverage,fuzzing",
    "--checks", "all",
    "--exclude-method", "DELETE",
    "--workers", "1",
    "--max-examples", "25",
    "--max-failures", "20",
    "--rate-limit", "120/m",
    "--request-timeout", "10",
    "--max-response-time", "5",
    "--report", "junit,har",
    "--report-dir", $ReportDir,
    "--header", "X-HBT-Security-Authorization:$($env:HBT_SECURITY_AUTHORIZATION_ID)"
)

if ($env:HBT_FUZZ_TOKEN) {
    $Arguments += @("--header", "Authorization:Bearer $($env:HBT_FUZZ_TOKEN)")
}

& $Schemathesis @Arguments
