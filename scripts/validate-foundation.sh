#!/usr/bin/env bash
# Validates the M1 foundation. Does not deploy metadata or log in to Salesforce.
set -euo pipefail
cd "$(dirname "$0")/.."
python -m unittest discover -s tests -v
