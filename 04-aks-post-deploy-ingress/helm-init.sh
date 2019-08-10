#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
STDIN=$(cat -)

# Env Name is passed as a json string
ENV_NAME=$(echo ${STDIN} | jq -c -r '.env' | tr -d '\n')
export HELM_HOME="${DIR}/.helm_${ENV_NAME}/"

# Return the calculated path to the local HELM_HOME
echo "{\"helm_home\": \"${HELM_HOME}\"}"
