#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
STDIN=$(cat -)

# Env Name is passed as a json string
ENV_NAME=$(echo ${STDIN} | jq -c -r '.env' | tr -d '\n')

# Create a local Helm Config Dir and init the client 
export HELM_HOME="${DIR}/.helm_${ENV_NAME}/"
helm init --client-only > /dev/null 2>&1

# Return the path to the local HELM_HOME
echo "{\"helm_home\": \"${HELM_HOME}\"}"
