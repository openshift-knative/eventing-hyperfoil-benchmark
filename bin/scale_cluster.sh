#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

scale_machineset "${NUM_WORKER_NODES}" || exit 1
