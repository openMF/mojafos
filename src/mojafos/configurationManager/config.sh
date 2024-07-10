#!/usr/bin/env bash

########################################################################
# GLOBAL VARS
########################################################################
BASE_DIR=$(pwd)
APPS_DIR="$BASE_DIR/src/mojafos/deployer/apps/"
INFRA_NAMESPACE="infra"
INFRA_RELEASE_NAME="mojafos-infra"
#mojaloop
MOJALOOPBRANCH="beta1"
MOJALOOPREPO_DIR="mojaloop"
MOJALOOP_NAMESPACE="mojaloop"
MOJALOOP_REPO_LINK="https://github.com/mojaloop/platform-shared-tools.git"
MOJALOOP_LAYER_DIRS=("$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/installer/manifests/crosscut" "$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/installer/manifests/ttk" "$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/installer/manifests/apps" "$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/installer/manifests/reporting")
MOJALOOP_VALUES_FILE="$BASE_DIR/src/mojafos/configurationManager/mojaloop_values.json"
#paymenthubee
PHBRANCH="v1.2.0-release"
PHREPO_DIR="ph"
PH_NAMESPACE="paymenthub"
PH_RELEASE_NAME="moja-ph"
PH_VALUES_FILE="$BASE_DIR/src/mojafos/deployer/ph_values.yaml"
PH_REPO_LINK="https://github.com/openMF/ph-ee-env-labs.git"
PH_HELM_REPO_LINK="https://fynarfin.io/images/ph-ee-g2psandbox-1.5.0/"
PH_G2P_CHART_VERSION="1.5.0"
PH_CHART_REPO_NAME="g2p-sandbox-1-5"
PH_EE_ENV_LABS_REPO_LINK="https://github.com/openMF/ph-ee-env-labs.git"
PH_EE_ENV_LABS_REPO_BRANCH="master"
PH_EE_ENV_LABS_REPO_DIR="ph_env_labs"
PH_EE_ENV_TEMPLATE_REPO_LINK="https://github.com/openMF/ph-ee-env-template.git"
PH_EE_ENV_TEMPLATE_REPO_BRANCH="master"
PH_EE_ENV_TEMPLATE_REPO_DIR="ph_template"
# Define Kubernetes service and MySQL connection details
MYSQL_SERVICE_NAME="mysql"  # Replace with your MySQL service name
MYSQL_SERVICE_PORT="3306"           # Replace with the MySQL service port
LOCAL_PORT="3307"                   # Local port to forward to
MAX_WAIT_SECONDS=60
# MySQL Connection Details
MYSQL_USER="root"
MYSQL_PASSWORD="ethieTieCh8ahv"
MYSQL_HOST="127.0.0.1"  # This is the localhost because we are port forwarding
SQL_FILE="$BASE_DIR/src/mojafos/deployer/setup.sql"

#fineract
FIN_NAMESPACE="fineract"
FIN_BRANCH="master"
FIN_REPO_LINK="https://github.com/fynarfin/fineract-env.git"
FIN_REPO_DIR="fineract"
FIN_NAMESPACE="fineract"
FIN_RELEASE_NAME="fineract"
FIN_VALUES_FILE="$BASE_DIR/src/mojafos/deployer/fin_values.yaml"

# Timers
START_TIME=$(date +%s)

########################################################################
# FUNCTIONS FOR CONFIGURATION MANAGEMENT
########################################################################
function replaceValuesInFiles() {
    local directories=("$@")
    local json_file="$MOJALOOP_VALUES_FILE"

    # Check if jq is installed, if not, exit with an error message
    if ! command -v jq &>/dev/null; then
        echo "Error: 'jq' is not installed. Please install it (https://stedolan.github.io/jq/) and make sure it's in your PATH."
        return 1
    fi

    # Check if the JSON file exists
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file '$json_file' does not exist."
        return 1
    fi

  # Loop over JSON objects in the file and call the process_json_object function
  jq -c '.[]' "$json_file" | while read -r json_object; do
      local file_name
      local old_value
      local new_value

      # Extract attributes from the JSON object
      file_name=$(echo "$json_object" | jq -r '.file_name')
      old_value=$(echo "$json_object" | jq -r '.old_value')
      new_value=$(echo "$json_object" | jq -r ".new_value")

      # Call the  function with the extracted attributes
      replaceValuesInFile "$file_name" "$old_value" "$new_value"
  done

  if [ $? -eq 0 ]; then
    echo -e "\n==> Mojaloop Manifests edited successfully"
  else
    echo -e "${RED}Mojaloop Manifests were not edited successfully${RESET}"
  fi
}

function createSecret(){
  local namespace="$1"
  echo -e "Creating secrets in the $namespace namespace"
  if make secrets -e NAMESPACE="$namespace" >> /dev/null 2>&1 ; then
    echo -e "${GREEN}Created secrets in the $namespace namespace${RESET}"
    return 0
  else
    echo -e "${RED}Creating secrets in the $namespace namespace${RESET} failed"
    exit 1
  fi
}

function configurePH() {
  local ph_chart_dir=$1
  local previous_dir="$PWD"  # Save the current working directory
  echo -e "${BLUE}Configuring Payment Hub ${RESET}"

  cd $ph_chart_dir || exit 1

  # Check if make is installed
  if ! command -v make &> /dev/null; then
      logWithVerboseCheck $debug info "make is not installed. Installing ..."
      sudo apt update >> /dev/null 2>&1
      sudo apt install -y make >> /dev/null 2>&1
      logWithVerboseCheck $debug info "ok"
  else
      logWithVerboseCheck $debug info "make is installed. Proceeding to configure"
  fi
  # create secrets for paymenthub namespace and infra namespace
  cd es-secret || exit 1
  createSecret "$PH_NAMESPACE"
  createSecret "$INFRA_NAMESPACE"
  cd ..
  cd kibana-secret || exit 1
  createSecret "$PH_NAMESPACE"
  createSecret "$INFRA_NAMESPACE"
  cd ..
  # kubectl create secret generic moja-ph-redis --from-literal=redis-password="" -n "$PH_NAMESPACE"

  # check if the configuration was successful
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Configuration of Paymenthub Successful${RESET}"
  else
    echo -e "${RED}Configuration of Paymenthub Failed${RESET}"
    exit 1
  fi

  # Return to the previous working directory
  cd "$previous_dir" || return 1
}

function configureFineract(){
  echo -e "${BLUE}Configuring fineract ${RESET}"
}

########################################################################
# FUNCTION TO MONITOR DEPLOYMENT
########################################################################
function monitorDeployment() {
  echo -e "${BLUE}Monitoring Deployment ${RESET}"

  echo -e "Waiting for all pods to be in 'Running' state..."
  start_time=$(date +%s)
  while true; do
    not_running_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running | wc -l)
    if [ "$not_running_pods" -eq 0 ]; then
      echo "All pods are in 'Running' state."
      break
    fi
    sleep 5
  done
  end_time=$(date +%s)
  total_time=$((end_time - start_time))
  echo -e "${GREEN}All pods are in 'Running' state. Total deploy time: ${total_time}s${RESET}"
}

########################################################################
# FUNCTION TO CHECK MEMORY USAGE
########################################################################
function checkMemoryUsage() {
  echo -e "${BLUE}Checking Memory Usage ${RESET}"
  kubectl top pods --all-namespaces | awk '
  NR==1 {print $0} 
  /mojaloop|paymenthub|fineract/ {print $0}'
}

########################################################################
# FUNCTION TO CHECK DISK SPACE USAGE
########################################################################
function checkDiskSpaceUsage() {
  echo -e "${BLUE}Checking Disk Space Usage ${RESET}"
  df -h | awk 'NR==1 || /\/$/ {print $0}'
}

########################################################################
# MAIN EXECUTION
########################################################################

# Run configuration functions
configureMojaloop
configurePH "$PHREPO_DIR"
configureFineract

# Monitor deployment
monitorDeployment

# Check memory and disk space usage
checkMemoryUsage
checkDiskSpaceUsage

END_TIME=$(date +%s)
TOTAL_DEPLOY_TIME=$((END_TIME - START_TIME))
echo -e "${GREEN}Total deployment time: ${TOTAL_DEPLOY_TIME}s${RESET}"

echo -e "${GREEN}Deployment and configuration complete.${RESET}"
