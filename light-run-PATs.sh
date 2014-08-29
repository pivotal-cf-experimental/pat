#!/bin/bash
# This requires the binary version of the PAT tool (`go build` will generate this binary in this repository)

# Exit on error
set -e

# Use local-config.yml and take test number as an optional argument
CONFIG_FILE=local-config.yml
TESTNUMBER=$1

# Create and target PAT-space
cf create-space PAT-space -o PAT-org
cf target -s PAT-space

# run PAT
./pat -config="${CONFIG_FILE}" 

# move latest test results to a human-readable name
# and put it in ./output to avoid problems w/non-PAT filenames in ./output/csvs
# mv output/csvs/`ls -ut output/csvs | head -1` "output/test-${CF_API}-${TEST_NUMBER}-l.csv"

# clean up test artifacts
cf delete-space -f PAT-space
