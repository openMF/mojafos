# A Deployable Package for Mifos/Fineract, Payment Hub EE, and Mojaloop (Mojafos)

## Introduction

The deployable package is intended to simplify and automate the deployment process of three software applications, namely Mojaloop, PaymentHub, and Fineract, onto a Kubernetes cluster. This package aims to streamline the deployment process, reduce manual errors, and enable someone to demo how these softwares can work together. 

## Latest versions
- Latest stable release of Fineract core banking system (1.9 or current)
- Latest stable version of Mojaloop (vNext)
- Latest stable release of Mifos X Web App (23.12 or later)
- Latest upstream version of Payment Hub EE

## Pre-requisites
Make sure you have the following before you go through this guide.
- You should be running Ubuntu 20.04 LTS on the machine where you are running this script
- 32GB of RAM
- 30GB+ free space in your home directory

# Quick Start
> NOTE: The deployment made by this script is meant for demo purposes and not for production

## Clone the repository
To use Mojafos, you need to clone the repository to be able to run the software scripts.
Clone the repository into a directory of your choice.
After cloning the repository,  you need to change the directory into the cloned repository.
``` 
git clone https://github.com/openMF/mojafos.git
```

Inside the directory run the following command to execute the script.

```
sudo ./run.sh -u $USER -m deploy -d true
```
### Options
- `-u` This is used to pass in the user the script should use to execute it's commands. The value passed in is `$USER` which the current user of the shell
- `-m` This option specifies the mode in which the script should execute. The available values are 
    - `deploy` - Deploy applications
    - `cleanup` - Undo what deploy did and clean up resources
- `-d` This flag tells the sccript whether to execute in verbose mode or not. The available values are :
    - true - Output should provide as much information as possible
    - false - Output should not be minimal

After running this command, it will run a few checks and then it will ask you whether you want to setup a kubernetes cluster locally or you want to connect to a remote one that is already configured using kubectl
```
Would you like to use a remote Kubernetes cluster or a local one? (remote/local): 
```
Choose your preferred option depending on where you want to run the kubernetes cluster to run the applications.
Enter remote to use a remote cluster and enter local to let the tool create a local cluster using k3s.
>Currently the tool is only tested on local kubernetes deployments but work is being done to test it on remote kubernetes clusters

After entering in your preferred option allow the script to run and deploy the softwares.

The script will start by deploying and configuring shared infrastructure to be used by the applications. After infrastructure has been deployed, you should see the following output

```bash
============================
Infrastructure Deployed
============================
```
The script will then prompt you upon completion of deployment of infrastructure to choose what kind of deployment you would like to make. 

There are three modes of deployment currently supported by Mojafos
- Only Mojaloop `moja`
- Only Fineract `fin`
- Only Payment Hub `ph`
- All Apps `all`

The prompt will look like this.
```bash
What would you like to Deploy? all/moja/fin/ph 
```

At the prompt type the mode you would like to use. 

After typing in the short code to represnt the mode you would want to install, the script will proceed to execute the installation as instructed.

If you enter invalide input, the script will default to deploying all apps.

If you chose `fin` or `all`, at some point in the script's execution, it will ask you for the number of fineract instances you would like to deploy.

```
How many instances of fineract would you like to deploy? Enter number:
```

Enter the number of instances you would like to deploy and press enter.

After  the script has successfully executed it will print the following output

```
========================================================================
Thank you for installing Mojaloop, Paymenthub and Fineract using Mojafos
========================================================================


TESTING
sudo ./run -u $USER -m test ml #For testing mojaloop
sudo ./run -u $USER -m test ph #For testing payment hub
sudo ./run -u $USER -m test fin #For testing fineract



CHECK DEPLOYMENTS USING kubectl
kubectl get pods -n mojaloop #For testing mojaloop
kubectl get pods -n paymenthub #For testing paymenthub
kubectl get pods -n fineract-n #For testing fineract. n is a number of a fineract instance


Copyright © 2023 The Mifos Initiative
```

## USING THE DEPLOYED APPS
TDB

## CONTRIBUTION
 TBD

## CONCLUSION

This tool is intended to simplify the deployment process for Payment Hub EE, Mojaloop and Fineract for testing purposes.





