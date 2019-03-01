#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

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

__VERBOSE=${__VERBOSE:=4}

# ------------------------------------------------------------------
# Mandatory Parameters
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:=""}
FIREWALL_NAME=${FIREWALL_NAME:=""}
COLLECTION_NAME=${COLLECTION_NAME:=""}

# ------------------------------------------------------------------
# Verbose Logging
.log 6 "[==== Mandatory Parameters ====]"
.log 6 "RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME"
.log 6 "FIREWALL_NAME=$FIREWALL_NAME"
.log 6 "COLLECTION_NAME=$COLLECTION_NAME"


# ------------------------------------------------------------------
param_errs=0
if [ -z "$RESOURCE_GROUP_NAME" ]; then .log 3 "Required environment variable not defined: RESOURCE_GROUP_NAME"; param_errs=$((param_errs + 1)); fi
if [ -z "$FIREWALL_NAME" ]; then .log 3 "Required environment variable not defined: FIREWALL_NAME"; param_errs=$((param_errs + 1)); fi
if [ -z "$COLLECTION_NAME" ]; then .log 3 "Required environment variable not defined: COLLECTION_NAME"; param_errs=$((param_errs + 1)); fi

if [ ${param_errs} -gt 0 ]; then
	.log 3 "Environment configuration invalid. Aborting..."
	exit 1
fi

az network firewall nat-rule collection delete --firewall-name $FIREWALL_NAME --resource-group $RESOURCE_GROUP_NAME \
  --collection-name $COLLECTION_NAME