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

__VERBOSE=${__VERBOSE:=6}

get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

usage() {
    echo "Usage: $0 [-e <environment_string>] [-p <prefix_string>] [-v vars_file] [-f (force flag)]" 1>&2; exit 1;
}

print_subription_context() {
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    CURRENT_SUBSCRIPTION_ID=$(az account list --all --query "[?isDefault].id | [0]" | tr -d '"')
    CURRENT_SUBSCRIPTION_NAME=$(az account list --all --query "[?isDefault].name | [0]" | tr -d '"')

    echo -e "${GREEN}[NOTE]${NC} Subscription Context: ${GREEN}${CURRENT_SUBSCRIPTION_NAME} (${CURRENT_SUBSCRIPTION_ID})${NC}"
    if [ "${f}" = true ]; then
        echo "Using ${CURRENT_SUBSCRIPTION_NAME} ($CURRENT_SUBSCRIPTION_ID)"
    else
        read -p "Continue with subscription (y/n)? " CONT
        if [ "$CONT" = "y" ]; then
            echo "Using ${CURRENT_SUBSCRIPTION_NAME} ($CURRENT_SUBSCRIPTION_ID)"
        else
            exit 1
        fi
    fi
}

run_terraform() {
    RT_IS_BACKEND=$1
    RT_ENV=$2
    RT_PREFIX=$3

    RT_MODULE=$4
    RT_VAR_FILE_PATH=$5
    RT_VAR_FILE_SPECIAL_ARGS=$6

    pushd $DIR
    cd $(echo -n "${DIR}/${RT_MODULE}")


    if [ "${RT_IS_BACKEND}" = true ]; then
        terraform init
    else
        terraform init -backend-config=./backend.tfvars
    fi

    if [ "${RT_IS_BACKEND}" = false ]; then
        TF_WORKSPACE=$(terraform workspace show)
        .log 6 "Current Workspace: ${TF_WORKSPACE}"
        if [ ${TF_WORKSPACE} = ${RT_ENV} ]; then
            .log 6 "No switch required: ${TF_WORKSPACE} = ${RT_ENV}"
        else
            .log 6 "Switch to workspace ${RT_ENV} required."
            EXISTING_WS=$(terraform workspace list)
            if [[ $EXISTING_WS =~ .*${RT_ENV}.* ]]; then
                .log 6 "Using existing workspace ${RT_ENV} "
                terraform workspace select ${RT_ENV}
            else
                .log 6 "Creating new workspace ${RT_ENV} "
                terraform workspace new ${RT_ENV}
                terraform workspace select ${RT_ENV}
            fi
        fi
    fi

    if [ "${f}" = true ]; then
        terraform plan -out=terraform.tfplan -var-file=${RT_VAR_FILE_PATH} -var "prefix=${RT_PREFIX}" $(echo -n ${RT_VAR_FILE_SPECIAL_ARGS}) && terraform apply terraform.tfplan
    else
        terraform plan -out=terraform.tfplan -var-file=${RT_VAR_FILE_PATH} -var "prefix=${RT_PREFIX}" $(echo -n ${RT_VAR_FILE_SPECIAL_ARGS})
        read -p "Continue with terraform apply (y/n)? " CONT
        if [ "$CONT" = "y" ]; then
            terraform apply terraform.tfplan
        else
            exit 1
        fi
    fi
    popd
}

e=""
p=""
v=""
f=false

while getopts ":e:v:p:f" o; do
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
        f)  f=true
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

.log 6 "[==== Verify Environment ====]"
$DIR/check_env.sh

VAR_FILE_PATH=$(get_abs_filename ${v})
print_subription_context

.log 6 "[==== 00 Terraform Backend State ====]"
run_terraform true ${e} ${p} "00-tf-backend" ${VAR_FILE_PATH} ""

.log 6 "[==== 01 AKS Resources ====]"
run_terraform false ${e} ${p} "02-aks" ${VAR_FILE_PATH} ""

.log 6 "[==== Done. ====]"
