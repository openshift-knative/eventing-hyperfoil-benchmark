#!/usr/bin/env bash

# This script is like `run.sh` but without the steps to install
# the system under test, so it's usable only when the system is
# already up and running.
#
# Inputs:
#   See inputs in run.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo_input_variables || exit 1

run || exit 1
