#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# ------------------------------------------------------------------
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# ------------------------------------------------------------------
# Logging
declare -A LOG_LEVELS

LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")
function .log() {
  local LEVEL=${1}
  shift
  if [ ${__VERBOSE} -ge ${LEVEL} ]; then
    if [ ${LEVEL} -ge 3 ]; then
      echo "[${LOG_LEVELS[$LEVEL]}]" "$@" 1>&2
    else
      echo "[${LOG_LEVELS[$LEVEL]}]" "$@"
    fi
  fi
}

__VERBOSE=${__VERBOSE:=6}
errors_count=0

if ! [[ -x "$(command -v jq)" ]]; then
  .log 3 "jq is required and was not found in PATH."
  errors_count=$((errors_count + 1))
fi

if ! [[ -x "$(command -v az)" ]]; then
  .log 3 "az (Azure CLI) is required and was not found in PATH."
  errors_count=$((errors_count + 1))
fi

if ! [[ -x "$(command -v helm)" ]]; then
  .log 3 "helm is required and was not found in PATH."
  errors_count=$((errors_count + 1))
fi

if ! [[ -x "$(command -v kubectl)" ]]; then
  .log 3 "kubectl is required and was not found in PATH."
  errors_count=$((errors_count + 1))
fi

if ! [[ -x "$(command -v terraform)" ]]; then
  .log 3 "terraform is required and was not found in PATH."
  errors_count=$((errors_count + 1))
fi

az_firewall_test="$(az extension list | jq 'map(.name) | index("azure-firewall")' | tr -d '\n')"
if ! [[ $az_firewall_test =~ ^[0-9]+ ]]; then
  .log 3 "az CLI firewall extension is not installed. install via 'az extension add -n azure-firewall'."
  errors_count=$((errors_count + 1))
fi

if [ ${errors_count} -gt 0 ]; then
  exit 1
fi
