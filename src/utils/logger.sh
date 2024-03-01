#!/usr/bin/env bash

# Text color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

function logWithLevel() {
  local logLevel=$1
  shift
  local logMessage=$@
  case "$logLevel" in
    "debug")
        echo -e "${BLUE}DEBUG${RESET} $logMessage "
        ;;
    "info")
        echo -e "${BLUE}INFO${RESET} $logMessage "
        ;;
    "warning")
        echo -e "${YELLOW}WARNING${RESET} $logMessage"
        ;;
    "error")
        echo -e "${RED}ERROR${RESET} $logMessage "
        ;;
    *) # Default case
        echo "$logMessage"
        ;;
  esac
}

function logWithVerboseCheck() {
  local verbose=$1
  local level=$2
  shift && shift
  local message=$@

  if [ "$verbose" = true ]; then
    logWithLevel $level $message
  fi
}

# verbose=true 
# logWithVerboseCheck $verbose debug "Hello World"

