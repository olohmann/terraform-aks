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

__VERBOSE=${__VERBOSE:=6}

# ------------------------------------------------------------------
# Mandatory Parameters
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:=""}
FIREWALL_NAME=${FIREWALL_NAME:=""}
COLLECTION_NAME=${COLLECTION_NAME:=""}
PRIORITY=${PRIORITY:=""}
RULE_NAME=${RULE_NAME:=""}
DESTINATION_ADDRESSES=${DESTINATION_ADDRESSES:=""}
DESTINATION_PORT=${DESTINATION_PORT:=""}
SOURCE_ADDRESSES=${SOURCE_ADDRESSES:=""}
TRANSLATED_ADDRESS=${TRANSLATED_ADDRESS:=""}
TRANSLATED_PORT=${TRANSLATED_PORT:=""}

# ------------------------------------------------------------------
# Verbose Logging
.log 6 "[==== Mandatory Parameters ====]"
.log 6 "RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME"
.log 6 "FIREWALL_NAME=$FIREWALL_NAME"
.log 6 "COLLECTION_NAME=$COLLECTION_NAME"
.log 6 "PRIORITY=$PRIORITY"
.log 6 "RULE_NAME=$RULE_NAME"
.log 6 "DESTINATION_ADDRESSES=$DESTINATION_ADDRESSES"
.log 6 "DESTINATION_PORT=$DESTINATION_PORT"
.log 6 "SOURCE_ADDRESSES=$SOURCE_ADDRESSES"
.log 6 "TRANSLATED_ADDRESS=$TRANSLATED_ADDRESS"
.log 6 "TRANSLATED_PORT=$TRANSLATED_PORT"


# ------------------------------------------------------------------
param_errs=0
if [ -z "$RESOURCE_GROUP_NAME" ]; then .log 3 "Required environment variable not defined: RESOURCE_GROUP_NAME"; param_errs=$((param_errs + 1)); fi
if [ -z "$FIREWALL_NAME" ]; then .log 3 "Required environment variable not defined: FIREWALL_NAME"; param_errs=$((param_errs + 1)); fi
if [ -z "$COLLECTION_NAME" ]; then .log 3 "Required environment variable not defined: COLLECTION_NAME"; param_errs=$((param_errs + 1)); fi
if [ -z "$PRIORITY" ]; then .log 3 "Required environment variable not defined: PRIORITY"; param_errs=$((param_errs + 1)); fi
if [ -z "$RULE_NAME" ]; then .log 3 "Required environment variable not defined: RULE_NAME"; param_errs=$((param_errs + 1)); fi
if [ -z "$DESTINATION_ADDRESSES" ]; then .log 3 "Required environment variable not defined: DESTINATION_ADDRESSES"; param_errs=$((param_errs + 1)); fi
if [ -z "$DESTINATION_PORT" ]; then .log 3 "Required environment variable not defined: DESTINATION_PORT"; param_errs=$((param_errs + 1)); fi
if [ -z "$SOURCE_ADDRESSES" ]; then .log 3 "Required environment variable not defined: SOURCE_ADDRESSES"; param_errs=$((param_errs + 1)); fi
if [ -z "$TRANSLATED_ADDRESS" ]; then .log 3 "Required environment variable not defined: TRANSLATED_ADDRESS"; param_errs=$((param_errs + 1)); fi
if [ -z "$TRANSLATED_PORT" ]; then .log 3 "Required environment variable not defined: TRANSLATED_PORT"; param_errs=$((param_errs + 1)); fi

if [ ${param_errs} -gt 0 ]; then
	.log 3 "Environment configuration invalid. Aborting..."
	exit 1
fi

# TODO: Look for existing rule, delete, re-create.
if echo x"$SOURCE_ADDRESSES" | grep '*' > /dev/null; then
  .log 6 "Quoting source address as * was detected"
  az network firewall nat-rule create --firewall-name "$FIREWALL_NAME" --resource-group "$RESOURCE_GROUP_NAME" \
    --collection-name "$COLLECTION_NAME" \
    --action Dnat \
    --name "$RULE_NAME" \
    --priority $PRIORITY \
    --destination-addresses "$DESTINATION_ADDRESSES" \
    --destination-ports "$DESTINATION_PORT" \
    --source-addresses "$SOURCE_ADDRESSES" \
    --translated-address "$TRANSLATED_ADDRESS" \
    --translated-port "$TRANSLATED_PORT" \
    --protocols "TCP" \
    --description "Ingress DNAT Configuration" 
else
  az network firewall nat-rule create --firewall-name "$FIREWALL_NAME" --resource-group "$RESOURCE_GROUP_NAME" \
    --collection-name "$COLLECTION_NAME" \
    --action Dnat \
    --name "$RULE_NAME" \
    --priority $PRIORITY \
    --destination-addresses "$DESTINATION_ADDRESSES" \
    --destination-ports "$DESTINATION_PORT" \
    --source-addresses $SOURCE_ADDRESSES \
    --translated-address "$TRANSLATED_ADDRESS" \
    --translated-port "$TRANSLATED_PORT" \
    --protocols "TCP" \
    --description "Ingress QKnows DNAT Configuration" 
fi

