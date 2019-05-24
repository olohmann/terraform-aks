#!/usr/bin/env bash
TF_SCRIPT_VERSION=0.4.0

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

get_abs_filename() {
    # $1 : relative filename
    if [ -z "$1" ]; then
        echo ""
    else
        echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    fi
}

get_tf_variables() {
    # Get env variables starting with __TF_, remote the __TF_ prefix and
    # automatically create a -var key=value options list.
    echo -n $(python -c 'import os; import sys; sys.stdout.write(" ".join(map(lambda x: "-var \"{key}={value}\"".format(key=x[5:].lower(),value=os.environ[x]), list(filter(lambda x: x.startswith("__TF_"), os.environ.keys())))))')
}

set_tf_output() {
    # Transform terraform outputs to environment vars with __TF_ prefix, that will be transferred to dependant sub-deployments.
    eval $(terraform output -json | python -c 'import sys, json; tf_output = json.load(sys.stdin); sys.stdout.write(";".join(map(lambda key: "export __TF_{key}=\"{value}\"".format(key=key, value=tf_output[key]["value"]), tf_output.keys())))')
}

usage() {
    echo "Usage: $0 [-e <environment_name>] [-i <tf_var_file>] [-v] [-f] [-p] [-h]" 1>&2
    echo "Version: ${RUN_TF_VERSION}"
    echo ""
    echo "Options"
    echo "-e <environment_name>    Defines an environment name that will be activated"
    echo "                         as a terraform workspace, e.g. 'dev', 'qa' or 'prod'."
    echo "                         Default is terraform's 'default'."
    echo "-i <tf_var_file>         Defines an OPTIONAL terraform variables file that"
    echo "                         contains terraform key value pairs.".
    echo "-v                       Validate: perform a terraform validation run."
    echo "-f                       Force: Defaults all interaction to yes."
    echo "-p                       Print env."
    echo "-h                       Help: Print this dialog and exit."
    echo ""
    echo "You can provide terraform params via passing '__TF_' prefixed environment vars."
    echo "For example:"
    echo "export __TF_location=northeurope"
    echo "Will pass a -var \"location=northeurope\" to all terraform invocations."
    exit 1
}

ensure_subription_context() {
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

BACKEND_CONFIG=""
ensure_terraform_backend() {
    RT_BACKEND=$1
    RT_VAR_FILE_PATH=$2
    RT_VARS=$(echo -n $(get_tf_variables))

    pushd $DIR
    cd $(echo -n "${DIR}/${RT_BACKEND}")

    # Delete state, we are always re-creating the local state for the backend.
    rm -f terraform.tfplan terraform.tfstate terraform.tfstate.backup
    terraform init

    if [ "${f}" = true ]; then
        if [ -z "${RT_VAR_FILE_PATH}" ]; then
            eval $(printf "terraform plan -input=false -out=terraform.tfplan %s" "${RT_VARS}") && terraform apply terraform.tfplan
        else
            eval $(printf "terraform plan -input=false -out=terraform.tfplan -var-file %s %s" "${RT_VAR_FILE_PATH}" "${RT_VARS}") && terraform apply terraform.tfplan
        fi
    else
        if [ -z "${RT_VAR_FILE_PATH}" ]; then
            eval $(printf "terraform plan -input=false -out=terraform.tfplan %s" "${RT_VARS}")
        else
            eval $(printf "terraform plan -input=false -out=terraform.tfplan -var-file %s %s" "${RT_VAR_FILE_PATH}" "${RT_VARS}")
        fi

        read -p "Continue with terraform apply (y/n)? " CONT
        if [ "$CONT" = "y" ]; then
            terraform apply terraform.tfplan
        else
            exit 1
        fi
    fi

    BACKEND_CONFIG="$(terraform output -json | jq -r '.backend_config_params.value' | tr -d '\n')"

    popd
}

run_terraform() {
    RT_VALIDATE_ONLY=$1
    RT_ENV=$2

    RT_MODULE=$3
    RT_VAR_FILE_PATH=$4
    RT_VARS=$(echo -n $(get_tf_variables))

    pushd $DIR
    cd $(echo -n "${DIR}/${RT_MODULE}")

    # Clean existing state file that links to a backend. This is idempotent and will
    # be re-created. This, however, avoids problems if you deployments from a single
    # source with different prefixes.
    rm -f .terraform/terraform.tfstate

    # Init with Backend config.
    eval $(printf "terraform init %s" "${BACKEND_CONFIG}")

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

    if [ ${RT_VALIDATE_ONLY} = false ]; then
        if [ -z "${RT_VAR_FILE_PATH}" ]; then
            eval $(printf "terraform plan -input=false -out=terraform.tfplan %s" "${RT_VARS}")
        else
            eval $(printf "terraform plan -input=false -out=terraform.tfplan -var-file %s %s" "${RT_VAR_FILE_PATH}" "${RT_VARS}")
        fi

        if [ "${f}" = true ]; then
            terraform apply terraform.tfplan
        else
            read -p "Continue with terraform apply (y/n)? " CONT
            if [ "$CONT" = "y" ]; then
                terraform apply terraform.tfplan
            else
                exit 1
            fi
        fi
    else
        if [ -z "${RT_VAR_FILE_PATH}" ]; then
            eval $(printf "terraform validate %s" "${RT_VARS}")
        else
            eval $(printf "terraform validate -var-file %s %s" "${RT_VAR_FILE_PATH}" "${RT_VARS}")
        fi
    fi
    set_tf_output
    popd
}

e="default"
i=""
v=false
p=false
f=false

while getopts ":e:i:vhfp" o; do
    case "${o}" in
    e)
        e=${OPTARG}
        ;;
    i)
        i=${OPTARG}
        ;;
    f)
        f=true
        ;;
    v)
        v=true
        ;;
    p)
        p=true
        ;;
    h)
        usage
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${e}" ]; then
    usage
fi

.log 6 "[==== Check Required Tools ====]"
/usr/bin/env bash $DIR/check_tools.sh

servicePrincipalId=${servicePrincipalId:=""}
if [ -z "${servicePrincipalId}" ]; then
    .log 6 "[==== Using local user (az login) ====]"
else
    .log 6 "[==== Using Service Principal ====]"
    export ARM_CLIENT_ID="${servicePrincipalId}"
    export ARM_CLIENT_SECRET="${servicePrincipalKey}"
    export ARM_SUBSCRIPTION_ID="$(az account list --all --query "[?isDefault].id | [0]" | tr -d '"')"
    export ARM_TENANT_ID="$(az account list --all --query "[?isDefault].tenantId | [0]" | tr -d '"')"
fi

if [ "${p}" = true ]; then
    env
fi

VAR_FILE_PATH=$(get_abs_filename "${i}")
ensure_subription_context

.log 6 "[==== 00 Ensure Terraform State Backend  ====]"
ensure_terraform_backend "00-tf-backend" "${VAR_FILE_PATH}"

.log 6 "[==== 01 Environment ====]"
if [ -z "${__TF_aks_cluster_sp_app_id}" ]; then
    .log 6 "Detected no AKS Cluster SP Config. Creating new SP..."
    run_terraform ${v} ${e} "01-env" "${VAR_FILE_PATH}"
else
    .log 6 "Detected AKS Cluster SP Config. Using existing SP..."
fi

.log 6 "[==== 02 AKS ====]"
run_terraform ${v} ${e} "02-aks" "${VAR_FILE_PATH}"

.log 6 "[==== 03 AKS Post Deploy ====]"
run_terraform ${v} ${e} "03-aks-post-deploy" "${VAR_FILE_PATH}"

.log 6 "[==== 04 AKS Post Deploy Ingress ====]"
run_terraform ${v} ${e} "04-aks-post-deploy-ingress" "${VAR_FILE_PATH}"

.log 6 "[==== Done. ====]"
