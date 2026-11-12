# Validates the M1 foundation. Does not deploy metadata or log in to Salesforce.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (Get-Command py -ErrorAction SilentlyContinue) {
    py -3 -m unittest discover -s tests -v
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    python -m unittest discover -s tests -v
} else {
    Write-Error "Python 3 is required to run the M1 foundation tests."
    exit 1
}

exit $LASTEXITCODE
