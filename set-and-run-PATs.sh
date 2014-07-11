#!/bin/bash
## **NB:** This script requires the `mktemp` tool.
## It uses only portable features of the tool, so it should work with any implementation of it that might be present.
##
## It also requires the binary version of the PAT tool (`go build` will generate this binary in this repository)
## $PATUSER and $PATPSWD must be set to admin for the targeted environment.

# Exit on error
set -e

# Take API and config file as an arguments
CF_API=$1
CONFIG_FILE=$2

# create and set random, temporary CF_HOME with an absolute path

export CF_HOME="${PWD}/$(mktemp -d random-cf-home.XXXXX)"

# login to CF, create and target PAT-space
cf api $CF_API --skip-ssl-validation
cf auth $PATUSER $PATPSWD
cf create-org PAT-org
cf create-space PAT-space -o PAT-org
cf target -o PAT-org -s PAT-space
cf set-quota PAT-org runaway

# run PAT
./pat -config="${CONFIG_FILE}" 

# move test results to a human-readable name
# and put it in ./output to avoid problems w/non-PAT filenames in ./output/csvs
## DISABLED - probably have to manage this manually until/unless I can figure out a slicker system
# mv output/csvs/*.csv "output/${CF_API}.csv"

# clean up test artifacts
cf delete-space -f PAT-space

# clean up random temporary CF_HOME
rm -rf $CF_HOME
