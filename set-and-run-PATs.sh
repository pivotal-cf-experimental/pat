#!/bin/bash
# **NB:** This script requires the `mktemp` tool.
# It uses only portable features of the tool, so it should work with any implementation of it that might be present.
#
# It also requires the binary version of the PAT tool (`go build` will generate this binary in this repository)
# $PATUSER and $PATPSWD must be set to admin for the targeted environment.

# Exit on error
set -e

# Take API, and config file and test number as arguments
CF_API=$1
CONFIG_FILE=$2
TEST_NUMBER=$3

# OR comment that section out and set them manually here, instead.
#CF_API=api.pivotal1.com
#CONFIG_FILE=local-config.yml
#TESTNUMBER=$1

# create and set random, temporary CF_HOME with an absolute path
export CF_HOME="${PWD}/$(mktemp -d random-cf-home.XXXXX)"

# load credentials into the environment
source ./credentials.sh

# login to CF, create and target PAT-space
cf api $CF_API --skip-ssl-validation
cf auth $PATUSER $PATPSWD
cf create-org PAT-org
cf create-space PAT-space -o PAT-org
cf target -o PAT-org -s PAT-space
cf set-quota PAT-org runaway

# run PAT
./pat -config="${CONFIG_FILE}" 

# move latest test results to a human-readable name
# and put it in ./output to avoid problems w/non-PAT filenames in ./output/csvs
mv output/csvs/`ls -ut output/csvs | head -1` "output/test-${CF_API}-${TEST_NUMBER}-a.csv"

# clean up test artifacts... and don't exit if they're already gone
cf delete-space -f PAT-space || true

# clean up random temporary CF_HOME
rm -rf $CF_HOME
