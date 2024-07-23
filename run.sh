#!/bin/bash

source ./src/utils/logger.sh
source ./src/mojafos/commandline/commandline.sh
source ./src/mojafos/environment/environment.sh

mode=""
user=""
k8_version=""
kubernetes_distro="k3s"
force_flag=false

while getopts "m:u:v:k:fh" opt; do
    case ${opt} in
        m)
            mode=$OPTARG
            if [[ ! "$mode" =~ ^(install|delete)$ ]]; then
                echo "Error: Invalid mode specified."
                showUsage
                exit 1
            fi
            ;;
        u)
            user=$OPTARG
            ;;
        v)
            k8_version=$OPTARG
            ;;
        k)
            kubernetes_distro=$OPTARG
            ;;
        f)
            force_flag=true
            ;;
        h)
            showUsage
            exit 0
            ;;
        *)
            showUsage
            exit 1
            ;;
    esac
done

if [ -z "$mode" ]; then
    echo "Error: Mode (-m) is required."
    showUsage
    exit 1
fi

echo "Mode: $mode"
echo "User: $user"
echo "Kubernetes Version: $k8_version"
echo "Kubernetes Distro: $kubernetes_distro"
echo "Force Flag: $force_flag"