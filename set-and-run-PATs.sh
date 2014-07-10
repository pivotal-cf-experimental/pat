#!/bin/bash
## **NB:** This script requires the `mktemp` tool.
## It uses only portable features of the tool, so it should work with any implementation of it that might be present.
##
## It also requires the binary version of the PAT tool, available at https://github.com/cloudfoundry-incubator/pat
##
## Finally, this script requires that a PAT-org be setup with adequite quota on the target CF, 
## and that $PATUSER and $PATPSWD are set to a user with permissions to push to that space.
## (The admin user is fine, but not required, for this.)

# Exit on error
set -e

# Take API and config file as an arguments
CF_API=$1
CONFIG_FILE=$2

# set random, temporary CF_HOME with an absolute path

export CF_HOME="${PWD}/"
export CF_HOME="${CF_HOME}$(mktemp -d random-cf-home.XXXXX)"

# login to CF, create and target PAT-space
cf api $CF_API --skip-ssl-validation
cf auth $PATUSER $PATPSWD
cf create-space PAT-space -o PAT-org
cf target -o PAT-org -s PAT-space

# run PAT
./pat -config="${CONFIG_FILE}" 

# move test results to a human-readable name
# and put it in ./output to avoid problems w/non-PAT filenames in ./output/csvs
mv output/csvs/*.csv "output/${CF_API}.csv"

# clean up test artifacts
cf delete-space -f PAT-space

# clean up random temporary CF_HOME
rm -rf $CF_HOME
