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

get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

usage() { echo "Usage: $0 [-e <environment_string>] [-p <prefix_string>] [-v vars_file]" 1>&2; exit 1; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
e=""
p=""
v=""

while getopts ":e:v:p:" o; do
    case "${o}" in
        e)
            e=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        v)
            v=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${e}" ] || [ -z "${p}" ] || [ -z "${v}" ]; then
    usage
fi

VAR_FILE_PATH=$(get_abs_filename ${v})

pushd $DIR
cd $DIR/00-env
.log 6 "[==== 00 Preparing Basic Environment and Service Principals ====]"

terraform init

TF_WORKSPACE=$(terraform workspace show)
.log 6 "Current Workspace: ${TF_WORKSPACE}"
if [ ${TF_WORKSPACE} = ${e} ]; then
    .log 6 "No switch required: ${TF_WORKSPACE} = ${e}"
else
    .log 6 "Switch to workspace ${e} required."
    terraform workspace new ${e}
    terraform workspace select ${e}
fi

terraform plan -out=terraform.tfplan -var-file=${VAR_FILE_PATH} -var "prefix=${p}" && terraform apply terraform.tfplan
popd 


pushd $DIR
cd $DIR/01-aks
.log 6 "[==== 01 Preparing AKS Environment ====]"

terraform init -backend-config=./${e}_backend.tfvars 

TF_WORKSPACE=$(terraform workspace show)
.log 6 "Current Workspace: ${TF_WORKSPACE}"
if [ ${TF_WORKSPACE} = ${e} ]; then
    .log 6 "No switch required: ${TF_WORKSPACE} = ${e}"
else
    .log 6 "Switch to workspace ${e} required."
    terraform workspace new ${e}
    terraform workspace select ${e}
fi

terraform plan -out=terraform.tfplan -var-file=${VAR_FILE_PATH} -var "prefix=${p}" -var-file=./${e}_aks_cluster_sp.generated.tfvars && terraform apply terraform.tfplan
popd 

pushd $DIR
cd $DIR/02-aks-post-deploy
.log 6 "[==== 02 Preparing AKS Post Deploy ====]"

terraform init -backend-config=./${e}_backend.tfvars 

TF_WORKSPACE=$(terraform workspace show)
.log 6 "Current Workspace: ${TF_WORKSPACE}"
if [ ${TF_WORKSPACE} = ${e} ]; then
    .log 6 "No switch required: ${TF_WORKSPACE} = ${e}"
else
    .log 6 "Switch to workspace ${e} required."
    terraform workspace new ${e}
    terraform workspace select ${e}
fi

terraform plan -out=terraform.tfplan --var-file=${VAR_FILE_PATH} && terraform apply terraform.tfplan
popd 

pushd $DIR
cd $DIR/03-aks-post-deploy-ingress
.log 6 "[==== 03 Preparing AKS Post Deploy for Ingress ====]"

terraform init -backend-config=./${e}_backend.tfvars 

TF_WORKSPACE=$(terraform workspace show)
.log 6 "Current Workspace: ${TF_WORKSPACE}"
if [ ${TF_WORKSPACE} = ${e} ]; then
    .log 6 "No switch required: ${TF_WORKSPACE} = ${e}"
else
    .log 6 "Switch to workspace ${e} required."
    terraform workspace new ${e}
    terraform workspace select ${e}
fi

terraform plan -out=terraform.tfplan -var-file=${VAR_FILE_PATH} -var-file=./${e}_firewall_config.generated.tfvars && terraform apply terraform.tfplan
popd 

