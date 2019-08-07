#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

# Script Versioning
TF_SCRIPT_VERSION=1.3.2

# Minimal Terraform Version for compatibility.
TF_MIN_VERSION=0.12.5

HASHICORP_GPG_SIG_FILE=$(mktemp)

# See: https://www.hashicorp.com/security.html
cat > $HASHICORP_GPG_SIG_FILE <<-EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFMORM0BCADBRyKO1MhCirazOSVwcfTr1xUxjPvfxD3hjUwHtjsOy/bT6p9f
W2mRPfwnq2JB5As+paL3UGDsSRDnK9KAxQb0NNF4+eVhr/EJ18s3wwXXDMjpIifq
fIm2WyH3G+aRLTLPIpscUNKDyxFOUbsmgXAmJ46Re1fn8uKxKRHbfa39aeuEYWFA
3drdL1WoUngvED7f+RnKBK2G6ZEpO+LDovQk19xGjiMTtPJrjMjZJ3QXqPvx5wca
KSZLr4lMTuoTI/ZXyZy5bD4tShiZz6KcyX27cD70q2iRcEZ0poLKHyEIDAi3TM5k
SwbbWBFd5RNPOR0qzrb/0p9ksKK48IIfH2FvABEBAAG0K0hhc2hpQ29ycCBTZWN1
cml0eSA8c2VjdXJpdHlAaGFzaGljb3JwLmNvbT6JATgEEwECACIFAlMORM0CGwMG
CwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEFGFLYc0j/xMyWIIAIPhcVqiQ59n
Jc07gjUX0SWBJAxEG1lKxfzS4Xp+57h2xxTpdotGQ1fZwsihaIqow337YHQI3q0i
SqV534Ms+j/tU7X8sq11xFJIeEVG8PASRCwmryUwghFKPlHETQ8jJ+Y8+1asRydi
psP3B/5Mjhqv/uOK+Vy3zAyIpyDOMtIpOVfjSpCplVRdtSTFWBu9Em7j5I2HMn1w
sJZnJgXKpybpibGiiTtmnFLOwibmprSu04rsnP4ncdC2XRD4wIjoyA+4PKgX3sCO
klEzKryWYBmLkJOMDdo52LttP3279s7XrkLEE7ia0fXa2c12EQ0f0DQ1tGUvyVEW
WmJVccm5bq25AQ0EUw5EzQEIANaPUY04/g7AmYkOMjaCZ6iTp9hB5Rsj/4ee/ln9
wArzRO9+3eejLWh53FoN1rO+su7tiXJA5YAzVy6tuolrqjM8DBztPxdLBbEi4V+j
2tK0dATdBQBHEh3OJApO2UBtcjaZBT31zrG9K55D+CrcgIVEHAKY8Cb4kLBkb5wM
skn+DrASKU0BNIV1qRsxfiUdQHZfSqtp004nrql1lbFMLFEuiY8FZrkkQ9qduixo
mTT6f34/oiY+Jam3zCK7RDN/OjuWheIPGj/Qbx9JuNiwgX6yRj7OE1tjUx6d8g9y
0H1fmLJbb3WZZbuuGFnK6qrE3bGeY8+AWaJAZ37wpWh1p0cAEQEAAYkBHwQYAQIA
CQUCUw5EzQIbDAAKCRBRhS2HNI/8TJntCAClU7TOO/X053eKF1jqNW4A1qpxctVc
z8eTcY8Om5O4f6a/rfxfNFKn9Qyja/OG1xWNobETy7MiMXYjaa8uUx5iFy6kMVaP
0BXJ59NLZjMARGw6lVTYDTIvzqqqwLxgliSDfSnqUhubGwvykANPO+93BBx89MRG
unNoYGXtPlhNFrAsB1VR8+EyKLv2HQtGCPSFBhrjuzH3gxGibNDDdFQLxxuJWepJ
EK1UbTS4ms0NgZ2Uknqn1WRU1Ki7rE4sTy68iZtWpKQXZEJa0IGnuI2sSINGcXCJ
oEIgXTMyCILo34Fa/C6VCm2WBgz9zZO8/rHIiQm1J5zqz0DrDwKBUM9C
=LYpS
-----END PGP PUBLIC KEY BLOCK-----
EOF

# Required external tools to be available on PATH.
REQUIRED_TOOLS=("wget" "unzip" "az" "jq" "python" "openssl" "curl" "gpg" "shasum" "kubectl" "helm")

declare TERRAFORM_PATH

# ------------------------------------------------------------------
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CURRENT_IP=$(curl -s 'https://api.ipify.org?format=json' | jq -r ".ip" | tr -d '\n')
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

# vercomp() Attribution: Dennis Williamson,
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
function vercomp() {
    if [[ $1 == $2 ]]
    then
        echo "="
        return 0
    fi

    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo "<"
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo ">1"
            return 0
        fi
    done

    echo "="
    return 0
}

function check_tools() {
    local tools=("$@")
    local errors_count=0
    for cmd in "${tools[@]}"
    do
        if ! [[ -x "$(command -v ${cmd})" ]]; then
            .log 3 "${cmd} is required and was not found in PATH."
            errors_count=$((errors_count + 1))
        else
            .log 6 "Found '${cmd}' in path"
        fi
    done

    if [ ${errors_count} -gt 0 ]; then
        exit 1
    fi
}

function get_os() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     machine=linux;;
        Darwin*)    machine=darwin;;
        *)          machine="UNKNOWN"
    esac
    echo ${machine}
}

function fix_tf_var_az_devops_env_vars() {
    .log 6 "Fixing AzureDevOps Environment Variable Capitialization"
    eval $(python -c 'import os;import sys;sys.stdout.write("\n".join(map(lambda x: "export TF_VAR_{key}={value}".format(key=x[7:].lower(),value=os.environ[x]), list(filter(lambda x: x.startswith("TF_VAR_"), os.environ.keys())))))')
    eval $(python -c 'import os;import sys;sys.stdout.write("\n".join(map(lambda x: "export __TF_{key}={value}".format(key=x[5:].lower(),value=os.environ[x]), list(filter(lambda x: x.startswith("__TF_"), os.environ.keys())))))')
}

function verify_signature() {
    local tf_path=$1
    local tf_dir=$(dirname ${tf_path})
    local tf_shas_file="${tf_path}_SHA256SUMS"
    local tf_sha_file="${tf_path}_SHA256SUM"
    local tf_shas_sig_file="${tf_path}_SHA256SUMS.sig"

    pushd $DIR
    cd ${tf_dir}
    .log 6 "Verifying signature file with Hashicorp's GPG's PubKey..."
    gpg -q --import ${HASHICORP_GPG_SIG_FILE}
    gpg -q --verify ${tf_shas_sig_file} ${tf_shas_file}

    .log 6 "Verifying terraform binary signature..."
    shasum -a 256 -c ${tf_sha_file}
    .log 6 "... success. Found valid terraform signature."
    popd
}

function get_terraform() {
    .log 6 "Downloading terraform client (v${TF_MIN_VERSION})..."
    local os_version=$(get_os)
    if [ "${os_version}" = "UNKNOWN" ]; then
        .log 2 "'run_tf.sh' only supports terraform download for Linux and MacOS."
        exit 1
    fi

    local terraform_download_url="https://releases.hashicorp.com/terraform/${TF_MIN_VERSION}/terraform_${TF_MIN_VERSION}_${os_version}_amd64.zip"
    local terraform_sha_sums_download_url="https://releases.hashicorp.com/terraform/${TF_MIN_VERSION}/terraform_${TF_MIN_VERSION}_SHA256SUMS"
    local terraform_sha_sums_sig_download_url="https://releases.hashicorp.com/terraform/${TF_MIN_VERSION}/terraform_${TF_MIN_VERSION}_SHA256SUMS.sig"
    local tmp_dir=$(mktemp -d)
    wget -q -O ${tmp_dir}/terraform_${TF_MIN_VERSION}_${os_version}_amd64.zip ${terraform_download_url}
    wget -q -O ${tmp_dir}/terraform_SHA256SUMS ${terraform_sha_sums_download_url}
    wget -q -O ${tmp_dir}/terraform_SHA256SUMS.sig ${terraform_sha_sums_sig_download_url}

    # Extract the single SHASUM
    cat ${tmp_dir}/terraform_SHA256SUMS | grep "terraform_${TF_MIN_VERSION}_${os_version}_amd64.zip" > ${tmp_dir}/terraform_SHA256SUM

    unzip -qq ${tmp_dir}/terraform_${TF_MIN_VERSION}_${os_version}_amd64.zip -d ${tmp_dir}
    echo -n "${tmp_dir}/terraform"
}

function get_abs_filename() {
    # $1 : relative filename
    if [ -z "$1" ]; then
        echo ""
    else
        echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    fi
}

function set_tf_output() {
    # Transform terraform outputs to environment vars with TF_VAR prefix, 
    # that will be transferred to dependant sub-deployments.
    # Empty ("") output values will be omitted!
    eval $(${TERRAFORM_PATH} output -json |  jq -r 'with_entries(select(.value.value!=""))' | python -c 'import sys, json; tf_output = json.load(sys.stdin); sys.stdout.write(";".join(map(lambda key: "export TF_VAR_{key}=\"{value}\"".format(key=key, value=tf_output[key]["value"]), tf_output.keys())))')
}

# Automatically finds all subfolders to "run_tf.sh" that have *.tf files.
function find_deployments() {
    local os_version=$(get_os)
    if [ "${os_version}" = "darwin" ]; then
        echo -n $(find . -type f -name '*.tf' | sed -E 's|/[^/]+$||' | sed -E 's/(.*)/"\1"/' | sort | uniq)
    elif [ "${os_version}" = "linux" ]; then
        echo -n $(find . -type f -name '*.tf' | sed -r 's|/[^/]+$||' | sed -r 's/(.*)/"\1"/' | sort | uniq)
    else
        .log 2 "OS not supported (only darwin|linux)."
        exit 1
    fi
}

function usage() {
    echo "Usage: $0 [-e <environment_name>] [-i <tf_var_file>] [-v] [-f] [-p] [-h]" 1>&2
    echo "Version: ${TF_SCRIPT_VERSION}"
    echo ""
    echo "Options"
    echo "-e <environment_name>    Defines an environment name that will be activated"
    echo "                         as a terraform workspace, e.g. 'dev', 'qa' or 'prod'."
    echo "                         Default is terraform's 'default'."
    echo "-v                       Validate: perform a terraform validation run."
    echo "-f                       Force: Defaults all interaction to yes."
    echo "-p                       Print env."
    echo "-d                       Download minimal version of terraform client."
    echo "-h                       Help: Print this dialog and exit."
    echo ""
    echo "Passing Terraform Variables:"
    echo "You can provide terraform params via passing 'TF_VAR_' prefixed environment vars."
    echo "Example:"
    echo "export TF_VAR_location=northeurope"
    echo "Will pass according variable to all terraform invocations."
    echo ""
    echo "Customize Terraform Backend configuration:"
    echo "export __TF_backend_resource_group_name=\"MySpecialName_RG\""
    echo "export __TF_backend_location=\"NorthEurope\""
    echo "export __TF_backend_storage_account_name=\"s98si89p\""
    echo "export __TF_backend_storage_container_name=\"tf-state\""
    echo ""
    echo "# comma separated list of IPs and/or CIDRs "
    echo "export __TF_backend_network_access_rules=\"23.92.28.29,126.20.2.0/24\""
    exit 1
}

function ensure_subription_context() {
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    CURRENT_SUBSCRIPTION_ID=$(az account list --all --query "[?isDefault].id | [0]" | tr -d '"')
    CURRENT_SUBSCRIPTION_NAME=$(az account list --all --query "[?isDefault].name | [0]" | tr -d '"')

    echo -e "[info] Subscription Context: ${GREEN}${CURRENT_SUBSCRIPTION_NAME} (${CURRENT_SUBSCRIPTION_ID})${NC}"
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

# Returns implicitely:
BACKEND_CONFIG=""
UNSET_BACKEND_DEPLOY_IP=""
function ensure_terraform_backend() {
    local RT_PREFIX=${TF_VAR_prefix:="contoso"}
    local RT_LOCATION=${TF_VAR_location:="westeurope"}
    local KEEP_CURRENT_IP=false
    # Initialize potential env vars.
    __TF_backend_resource_group_name=${__TF_backend_resource_group_name:=""}
    __TF_backend_location=${__TF_backend_location:=""}
    __TF_backend_storage_account_name=${__TF_backend_storage_account_name:=""}

    local RT_BACKEND_RESOURCE_GROUP_NAME=$([ -z "${__TF_backend_resource_group_name}" ] && echo "${RT_PREFIX}-shared-tf-state-rg" || echo "${__TF_backend_resource_group_name}")
    local RT_BACKEND_RESOURCE_GROUP_LOCATION=$([ -z "${__TF_backend_location}" ] && echo "${RT_LOCATION}" || echo "${__TF_backend_location}")

    az group create \
      --name "${RT_BACKEND_RESOURCE_GROUP_NAME}" \
      --location "${RT_BACKEND_RESOURCE_GROUP_LOCATION}" \
      --output none

    local RT_RG_ID=$(az group show -n ${RT_BACKEND_RESOURCE_GROUP_NAME} -o json | jq -r '.id' | tr -d '\n')
    local RT_HASH_SUFFIX_FULL=$(echo -n "${RT_RG_ID}" | openssl dgst -sha256 | sed 's/^.* //' | tr -d '\n')
    local RT_HASH_SUFFIX=${RT_HASH_SUFFIX_FULL:0:6}

    local RT_BACKEND_STORAGE_ACC_NAME=$([ -z "${__TF_backend_storage_account_name}" ] && echo "${RT_PREFIX}${RT_HASH_SUFFIX}" || echo "${__TF_backend_storage_account_name}")
    local RT_BACKEND_STORAGE_ACC_LOCATION=${RT_BACKEND_RESOURCE_GROUP_LOCATION}
    local RT_BACKEND_STORAGE_ACC_NETWORK_RULES=${__TF_backend_network_access_rules:=""}
    local RT_BACKEND_STORAGE_ACC_CONTAINER_NAME=${__TF_backend_storage_container_name:="tf-state"}

    az storage account create \
      --name "${RT_BACKEND_STORAGE_ACC_NAME}" \
      --resource-group "${RT_BACKEND_RESOURCE_GROUP_NAME}" \
      --location "${RT_BACKEND_RESOURCE_GROUP_LOCATION}" \
      --sku "Standard_LRS" \
      --kind "BlobStorage" \
      --access-tier "Hot" \
      --encryption-service "blob" \
      --encryption-service "file" \
      --https-only "true" \
      --default-action "Allow" \
      --bypass "None" \
      --output none

    local RT_BACKEND_ACCESS_KEY=$(az storage account keys list --account-name ${RT_BACKEND_STORAGE_ACC_NAME} | jq -r '.[0].value' | tr -d '\n')
    .log 6 "Creating container for state storage..."
    az storage container create \
      --account-name "${RT_BACKEND_STORAGE_ACC_NAME}" \
      --account-key "${RT_BACKEND_ACCESS_KEY}" \
      --name "${RT_BACKEND_STORAGE_ACC_CONTAINER_NAME}" \
      --public-access "off" \
      --auth-mode key \
      --output none

    .log 6 "Dropping existing network rules..."
    local RT_EXISTING_NETWORK_RULES=$(az storage account network-rule list --account-name ${RT_BACKEND_STORAGE_ACC_NAME} | jq -r '.ipRules[].ipAddressOrRange')
    while read -r entry; do
        az storage account network-rule remove \
         --resource-group "${RT_BACKEND_RESOURCE_GROUP_NAME}" \
         --account-name "${RT_BACKEND_STORAGE_ACC_NAME}" \
         --ip-address "${entry}" \
         --output none
    done <<< "${RT_EXISTING_NETWORK_RULES}"

    local RT_NEW_NETWORK_RULES=$(echo -n "${RT_BACKEND_STORAGE_ACC_NETWORK_RULES}" | tr ',' '\n')
    while read -r entry; do
        if [[ ${entry} =~ ^\ +$ ]]; then
            .log 6 "No additional network rule changes required."
        elif [[ -z "${entry}" ]]; then
            .log 6 "No additional network rule changes required."
        else
            .log 6 "Adding FW exception for '${entry}'"
            az storage account network-rule add \
                --resource-group "${RT_BACKEND_RESOURCE_GROUP_NAME}" \
                --account-name "${RT_BACKEND_STORAGE_ACC_NAME}" \
                --ip-address "${entry}" \
                --output none
        fi
    done <<< "${RT_NEW_NETWORK_RULES}"

    # Set Global variable
    BACKEND_CONFIG="-backend-config 'resource_group_name=${RT_BACKEND_RESOURCE_GROUP_NAME}' -backend-config 'storage_account_name=${RT_BACKEND_STORAGE_ACC_NAME}' -backend-config 'container_name=${RT_BACKEND_STORAGE_ACC_CONTAINER_NAME}' -backend-config 'access_key=${RT_BACKEND_ACCESS_KEY}'"
    UNSET_BACKEND_DEPLOY_IP="az storage account update --name \"${RT_BACKEND_STORAGE_ACC_NAME}\" --default-action \"Deny\" --output none"
}

function run_terraform() {
    local RT_VALIDATE_ONLY=$1
    local RT_ENV=$2
    local RT_MODULE=$3

    pushd $DIR
    cd "$(echo -n "${RT_MODULE}")"

    # Clean existing state file that links to a backend. This is idempotent and will
    # be re-created. This, however, avoids problems if you deployments from a single
    # source with different prefixes.
    rm -f .terraform/terraform.tfstate
    rm -rf .terraform/terraform.tfstate.d/
    rm -f .terraform/environment

    # Init with Backend config.
    eval $(printf "${TERRAFORM_PATH} init %s -no-color" "${BACKEND_CONFIG}")

    TF_WORKSPACE=$(${TERRAFORM_PATH} workspace show)
    .log 6 "Current Workspace: ${TF_WORKSPACE}"
    if [ ${TF_WORKSPACE} = ${RT_ENV} ]; then
        .log 6 "No switch required: ${TF_WORKSPACE} = ${RT_ENV}"
    else
        .log 6 "Switch to workspace ${RT_ENV} required."
        EXISTING_WS=$(${TERRAFORM_PATH} workspace list)
        if [[ $EXISTING_WS =~ .*${RT_ENV}.* ]]; then
            .log 6 "Using existing workspace ${RT_ENV} "
            ${TERRAFORM_PATH} workspace select ${RT_ENV}
        else
            .log 6 "Creating new workspace ${RT_ENV} "
            ${TERRAFORM_PATH} workspace new ${RT_ENV}
            ${TERRAFORM_PATH} workspace select ${RT_ENV}
        fi
    fi

    if [ ${RT_VALIDATE_ONLY} = false ]; then
        ${TERRAFORM_PATH} plan -no-color -input=false -out=terraform.tfplan

        if [ "${f}" = true ]; then
            ${TERRAFORM_PATH} apply -no-color terraform.tfplan
        else
            read -p "Continue with terraform apply (y/n)? " CONT
            if [ "$CONT" = "y" ]; then
                ${TERRAFORM_PATH} apply -no-color terraform.tfplan
            else
                exit 1
            fi
        fi
    else
        ${TERRAFORM_PATH} validate -no-color
    fi
    set_tf_output
    popd
}

# =============================================
# Check Options
e="default"
i=""
v=false
p=false
f=false
d=false

while getopts ":e:i:vhfpd" o; do
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
    d)
        d=true
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

fix_tf_var_az_devops_env_vars

.log 6 "[==== Check Required Tools ====]"
.log 6 "Found 'bash' (version: ${BASH_VERSION})"
check_tools "${REQUIRED_TOOLS[@]}"

if [ "${d}" = true ]; then
    TERRAFORM_PATH=$(get_terraform)
    verify_signature "${TERRAFORM_PATH}"
else
    TERRAFORM_PATH=$(which terraform | tr -d '\n')
fi

.log 6 "Using terraform exectuable at '${TERRAFORM_PATH}'"

TF_VERSION=$(echo -n $(${TERRAFORM_PATH} version) | head -1 | cut -d'v' -f2)
TF_VER_COMP=$(vercomp $TF_MIN_VERSION $TF_VERSION)
if [[ ${TF_VER_COMP} == "<" ]]; then
    .log 2 "Minimum terraform version required: ${TF_MIN_VERSION} (found: ${TF_VERSION})"
    exit 1
else
    .log 6 "Found terraform ${TF_VERSION} (minimum: ${TF_MIN_VERSION})"
fi

# Determine if we are running under Azure DevOps or local
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

ensure_subription_context

.log 6 "[==== Ensure Terraform State Backend  ====]"
ensure_terraform_backend

# Need OS version to control BSD/Linux sed flags which are used in next steps.
os_version=$(get_os)
if [ "${os_version}" = "darwin" ]; then
    sed_flag="-E"
elif [ "${os_version}" = "linux" ]; then
    sed_flag="-r"
else
    .log 2 "Unsupported OS. Only darwin/linux supported."
fi

# Use find to traverse all direct sub-dirs that have .tf files (=deployments).
# Store the modules in a temporary file which is used to turn the results into an array.
declare -a deployments
deployments=()
deployments_temp_file=$(mktemp)
find ${DIR} -maxdepth 2 -type f -name '*.tf' | sed ${sed_flag} 's|/[^/]+$||' | sort | uniq > ${deployments_temp_file}
while read -r deployment; do
    deployments+=("${deployment}")
done < ${deployments_temp_file}
rm ${deployments_temp_file}

# Run through the array of deployments and issue the terraform validate/plan/apply process.
for deployment in "${deployments[@]}"
do
    .log 6 "[==== Running Deployment: ${deployment} ====]"
    run_terraform ${v} ${e} "${deployment}"
done

.log 6 "[==== Cleanup ====]"
.log 6 "Remove current IP from terraform state backend ip rules..."
eval $(echo -n "${UNSET_BACKEND_DEPLOY_IP}")

.log 6 "[==== All done. ====]"
