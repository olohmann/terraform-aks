#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# ------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# ------------------------------------------------------------------
# Logging
declare -A LOG_LEVELS
LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")
function .log () {
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
read -p "Are you sure you want to delete all untracked and ignored files? Note: all temporary secrets (secrets.*.tfvars) will be preserved. (y/n)? " CONT
if [ "$CONT" = "y" ]; then
    TMP_DIR=$(mktemp -d)
    cp ${DIR}/secrets.*.tfvars ${TMP_DIR}/.
    cp ${DIR}/secrets*.tfvars ${TMP_DIR}/.
    git clean -fdx
    mv -f ${TMP_DIR}/* .
    rmdir ${TMP_DIR}
else
    exit 1
fi
