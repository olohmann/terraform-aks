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
<<<<<<< HEAD
    else 
=======
    else
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
		echo "[${LOG_LEVELS[$LEVEL]}]" "$@"
	fi
  fi
}

__VERBOSE=${__VERBOSE:=6}

get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

<<<<<<< HEAD
usage() { 
    echo "Usage: $0 [-e <environment_string>] [-p <prefix_string>] [-v vars_file] [-i (interactive flag)]" 1>&2; exit 1; 
=======
usage() {
    echo "Usage: $0 [-e <environment_string>] [-p <prefix_string>] [-v vars_file] [-i (interactive flag)]" 1>&2; exit 1;
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
}

print_subription_context() {
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    CURRENT_SUBSCRIPTION_ID=$(az account list --all --query "[?isDefault].id | [0]" | tr -d '"')
    CURRENT_SUBSCRIPTION_NAME=$(az account list --all --query "[?isDefault].name | [0]" | tr -d '"')

    echo -e "${GREEN}[NOTE]${NC} Subscription Context: ${GREEN}${CURRENT_SUBSCRIPTION_NAME} (${CURRENT_SUBSCRIPTION_ID})${NC}"
    if [ "${i}" = true ]; then
        read -p "Continue with subscription (y/n)? " CONT
        if [ "$CONT" = "y" ]; then
            echo "Using ${CURRENT_SUBSCRIPTION_NAME} ($CURRENT_SUBSCRIPTION_ID)"
        else
            exit 1
        fi
    else
        echo ""
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
<<<<<<< HEAD
            terraform workspace new ${RT_ENV}
            terraform workspace select ${RT_ENV}
=======
            EXISTING_WS=$(terraform workspace list)
            if [[ $EXISTING_WS =~ .*${RT_ENV}.* ]]; then
                .log 6 "Using existing workspace ${RT_ENV} "
                terraform workspace select ${RT_ENV}
            else
                .log 6 "Creating new workspace ${RT_ENV} "
                terraform workspace new ${RT_ENV}
                terraform workspace select ${RT_ENV}
            fi
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
        fi
    fi

    if [ "${i}" = true ]; then
<<<<<<< HEAD
        terraform plan -out=terraform.tfplan -var-file=${RT_VAR_FILE_PATH} -var "prefix=${RT_PREFIX}" $(echo -n ${RT_VAR_FILE_SPECIAL_ARGS}) 
=======
        terraform plan -out=terraform.tfplan -var-file=${RT_VAR_FILE_PATH} -var "prefix=${RT_PREFIX}" $(echo -n ${RT_VAR_FILE_SPECIAL_ARGS})
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
        read -p "Continue with terraform apply (y/n)? " CONT
        if [ "$CONT" = "y" ]; then
            terraform apply terraform.tfplan
        else
            exit 1
        fi
    else
        terraform plan -out=terraform.tfplan -var-file=${RT_VAR_FILE_PATH} -var "prefix=${RT_PREFIX}" $(echo -n ${RT_VAR_FILE_SPECIAL_ARGS}) && terraform apply terraform.tfplan
    fi
<<<<<<< HEAD
    popd 
=======
    popd
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
}

e=""
p=""
v=""
i=false

while getopts ":e:v:p:i" o; do
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
        i)  i=true
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
print_subription_context

.log 6 "[==== 00 Terraform Backend State ====]"
<<<<<<< HEAD
run_terraform true ${e} ${p} "00-tf-backend" ${VAR_FILE_PATH} "" 

.log 6 "[==== 01 Service Principals for AKS ====]"
run_terraform false ${e} ${p} "01-env" ${VAR_FILE_PATH} "" 

.log 6 "[==== 02 AKS Resources ====]"
run_terraform false ${e} ${p} "02-aks" ${VAR_FILE_PATH} "-var-file=./${e}_aks_cluster_sp.generated.tfvars" 
=======
run_terraform true ${e} ${p} "00-tf-backend" ${VAR_FILE_PATH} ""

.log 6 "[==== 01 Service Principals for AKS ====]"
run_terraform false ${e} ${p} "01-env" ${VAR_FILE_PATH} ""

.log 6 "[==== 02 AKS Resources ====]"
run_terraform false ${e} ${p} "02-aks" ${VAR_FILE_PATH} "-var-file=./${e}_aks_cluster_sp.generated.tfvars"
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c

.log 6 "[==== 03 AKS Cluster: RBAC ====]"
run_terraform false ${e} ${p} "03-aks-post-deploy" ${VAR_FILE_PATH} ""

.log 6 "[==== 04 AKS Cluster: Ingress ====]"
<<<<<<< HEAD
run_terraform false ${e} ${p} "04-aks-post-deploy-ingress" ${VAR_FILE_PATH} "-var-file=./${e}_firewall_config.generated.tfvars" 

.log 6 "[==== Done. ====]"
=======
run_terraform false ${e} ${p} "04-aks-post-deploy-ingress" ${VAR_FILE_PATH} "-var-file=./${e}_firewall_config.generated.tfvars"

.log 6 "[==== Done. ====]"
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
