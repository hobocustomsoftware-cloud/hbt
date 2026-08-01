$ErrorActionPreference = "Stop"
$Backend = Join-Path $PSScriptRoot "..\backend"
$Python = Join-Path $Backend ".venv\Scripts\python.exe"
$env:SEMGREP_LOG_FILE = Join-Path $Backend ".cache\semgrep.log"
$env:SEMGREP_SETTINGS_FILE = Join-Path $Backend ".cache\semgrep-settings.yml"
$env:SEMGREP_VERSION_CACHE_PATH = Join-Path $Backend ".cache\semgrep-version"

Push-Location $Backend
try {
    & $Python manage.py check --deploy
    & $Python manage.py makemigrations --check --dry-run
    & $Python manage.py spectacular --file openapi.yaml --validate --fail-on-warn
    & $Python manage.py test --noinput
    & $Python -m pip check
    & $Python -m pip_audit --requirement requirements.txt --cache-dir .cache/pip-audit --format json --output pip-audit-report.json
    & $Python -m bandit -r apps config -c ../security/bandit.yaml -f json -o bandit-report.json
    & $Python -m semgrep --metrics off --disable-version-check --jobs 1 --config ../security/.semgrep.yml apps config
}
finally {
    Pop-Location
}
