manifests_dir="installation/manifests/product"
default_manifests="${manifests_dir}/000-subscription-serverless.yaml,${manifests_dir}/000-subscription-hyperfoil.yaml,${manifests_dir}/000-subscription-amq-streams.yaml,${manifests_dir}/100-kafka.yaml,${manifests_dir}/100-hyperfoil.yaml,${manifests_dir}/100-knative-eventing.yaml,${manifests_dir}/100-knative-kafka.yaml"

cluster_domain="$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}')"
default_hyperfoil_server_url="hyperfoil-cluster-hyperfoil.${cluster_domain}"
export HYPERFOIL_SERVER_URL=${HYPERFOIL_SERVER_URL:-${default_hyperfoil_server_url}}
export KNATIVE_MANIFESTS=${KNATIVE_MANIFESTS-$default_manifests}
export SKIP_DELETE_RESOURCES=${SKIP_DELETE_RESOURCES:-false}
export TEST_CASE_NAMESPACE=${TEST_CASE_NAMESPACE-"perf-test"}
export WORKER_ONE=${WORKER_ONE:-node-role.kubernetes.io/worker=""}

alias kubectl=oc

function create_namespaces {
  echo "Creating namespaces"
  oc create ns kafka --dry-run=client -oyaml | oc apply -f - || return $?
}

function delete_test_namespace {
  if [ -z "${TEST_CASE_NAMESPACE}" ]; then
    oc delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found --timeout=10m || return $?
  fi
}

function delete_namespaces {
  # TODO(pierDipi) run must-gather(s) or backup prometheus metrics for further analysis.
  echo "Deleting namespaces"
  delete_test_namespace || return $?
  oc delete ns kafka --ignore-not-found --timeout=30m || return $?
  oc delete ns knative-eventing --ignore-not-found --timeout=30m || return $?
}

function apply_manifests() {
  create_namespaces || return $?

  # Extract manifests from the comma-separated list of manifests
  IFS=\, read -ra manifests <<<"${KNATIVE_MANIFESTS}"

  for x in "${manifests[@]}"; do
    echo "Applying ${x}"
    envsubst <"${x}" | oc apply -f - || return $?
    sleep 30
    wait_for_operators_to_be_running || return $?
  done

  wait_for_workloads_to_be_running || exit 1
}

function delete_manifests() {
  if ${SKIP_DELETE_RESOURCES}; then
    return 0
  fi

  delete_test_namespace || return $?

  # Extract manifests from the comma-separated list of manifests
  IFS=\, read -ra manifests <<<"${KNATIVE_MANIFESTS}"

  # Delete manifests in reverse order.
  n=${#manifests[*]} # Get the number of manifests to delete
  for ((i = n - 1; i >= 0; i--)); do
    echo "Deleting ${manifests[$i]}"
    oc delete -f "${manifests[$i]}" --ignore-not-found || return $?
  done

  delete_namespaces || return $?
}

function apply_test_resources() {
  oc create ns "${TEST_CASE_NAMESPACE}" --dry-run=client -oyaml | oc apply -f - || return $?
  # Before applying resources replace environment variables.
  oc apply -n "${TEST_CASE_NAMESPACE}" --dry-run=client -f "${TEST_CASE}/resources" -oyaml | envsubst | oc apply -f - || return $?
}

function run() {

  echo "Running test ${TEST_CASE}"

  echo_input_variables || return $?

  # Retry conflict errors like [1] by retrying.
  # [1] Operation cannot be fulfilled on brokers.eventing.knative.dev "kafka-broker-ordered": the object has been
  #     modified; please apply your changes to the latest version and try again
  apply_test_resources || apply_test_resources || return $?

  # Wait for all possible resources to be ready
  wait_for_resources_to_be_ready "brokers.eventing.knative.dev" || return $?
  wait_for_resources_to_be_ready "triggers.eventing.knative.dev" || return $?
  wait_for_resources_to_be_ready "channels.messaging.knative.dev" || return $?
  wait_for_resources_to_be_ready "subscriptions.messaging.knative.dev" || return $?
  wait_for_resources_to_be_ready "kafkachannels.messaging.knative.dev" || return $?
  wait_for_resources_to_be_ready "kafkasources.sources.knative.dev" || return $?

  # Inject additional env variables for test case specific configurations.
  source "${TEST_CASE}"/additional.sh
  echo "HTTP_TARGET ${HTTP_TARGET}"

  # Replace via `envsubst` variables based on the Broker
  HTTP_HOST=$(HTTP_TARGET=$HTTP_TARGET python3 -c "from urllib.parse import urlparse; import os; url = urlparse(os.environ['HTTP_TARGET']); print(f'{url.scheme}://{url.netloc}')")
  HTTP_PATH=$(HTTP_TARGET=$HTTP_TARGET python3 -c "from urllib.parse import urlparse; import os; print(urlparse(os.environ['HTTP_TARGET']).path)")
  export HTTP_PATH HTTP_HOST
  # shellcheck disable=SC2016
  envsubst '$HTTP_HOST $HTTP_PATH $WORKER_ONE' <"${TEST_CASE}/hf.yaml" >/tmp/hf.yaml || return $?

  # Run benchmark
  $(dirname "${BASH_SOURCE[0]}")/run_benchmark.py || return $?
}

function wait_for_resources_to_be_ready() {
  echo "Waiting for ${1} in ${TEST_CASE_NAMESPACE} to be ready"
  oc get "${1}" -n "${TEST_CASE_NAMESPACE}" |
    awk '{print $1}' | # Extract resource name
    tail -n +2 |       # skip header
    xargs -I{} oc wait "${1}" -n "${TEST_CASE_NAMESPACE}" {} --timeout 300s --for=condition=Ready=True || return $?
}

function wait_for_operators_to_be_running() {
  oc get subscription.operators.coreos.com -n openshift-operators |
    awk '{print $1}' | # Extract resource name
    tail -n +2 |       # skip header
    xargs -I{} oc wait subscription.operators.coreos.com -n openshift-operators {} --timeout 300s --for=jsonpath='{.status.state}'=AtLatestKnown || return $?

  oc get csv -n openshift-operators |
    awk '{print $1}' | # Extract resource name
    tail -n +2 |       # skip header
    xargs -I{} oc wait csv -n openshift-operators {} --timeout 300s --for=jsonpath='{.status.phase}'=Succeeded || return $?
}

function wait_for_workloads_to_be_running() {
  echo "Waiting for pods to be running"
  sleep 120 # This gives time to dynamic pods to be created.
  wait_until_pods_running "kafka" || return $?
  wait_until_pods_running "knative-eventing" || return $?
  wait_until_pods_running "hyperfoil" || return $?
}

# Copied from https://github.com/knative/hack/blob/0456e8bf65476e200785565da7c19382e271cae2/library.sh#L215-L265
#
# Waits until all pods are running in the given namespace.
# This function handles some edge cases that `kubectl wait` does not support,
# and it provides nice debug info on the state of the pod if it failed,
# that’s why we have this long bash function instead of using `kubectl wait`.
# Parameters: $1 - namespace.
function wait_until_pods_running() {
  echo -n "Waiting until all pods in namespace $1 are up"
  local failed_pod=""
  for i in {1..150}; do # timeout after 5 minutes
    # List all pods. Ignore Terminating pods as those have either been replaced through
    # a deployment or terminated on purpose (through chaosduck for example).
    local pods="$(kubectl get pods --no-headers -n $1 | grep -v Terminating)"
    # All pods must be running (ignore ImagePull error to allow the pod to retry)
    local not_running_pods=$(echo "${pods}" | grep -v Running | grep -v Completed | grep -v ErrImagePull | grep -v ImagePullBackOff)
    if [[ -n "${pods}" ]] && [[ -z "${not_running_pods}" ]]; then
      # All Pods are running or completed. Verify the containers on each Pod.
      local all_ready=1
      while read pod; do
        local status=($(echo -n ${pod} | cut -f2 -d' ' | tr '/' ' '))
        # Set this Pod as the failed_pod. If nothing is wrong with it, then after the checks, set
        # failed_pod to the empty string.
        failed_pod=$(echo -n "${pod}" | cut -f1 -d' ')
        # All containers must be ready
        [[ -z ${status[0]} ]] && all_ready=0 && break
        [[ -z ${status[1]} ]] && all_ready=0 && break
        [[ ${status[0]} -lt 1 ]] && all_ready=0 && break
        [[ ${status[1]} -lt 1 ]] && all_ready=0 && break
        [[ ${status[0]} -ne ${status[1]} ]] && all_ready=0 && break
        # All the tests passed, this is not a failed pod.
        failed_pod=""
      done <<<"$(echo "${pods}" | grep -v Completed)"
      if ((all_ready)); then
        echo -e "\nAll pods are up:\n${pods}"
        return 0
      fi
    elif [[ -n "${not_running_pods}" ]]; then
      # At least one Pod is not running, just save the first one's name as the failed_pod.
      failed_pod="$(echo "${not_running_pods}" | head -n 1 | cut -f1 -d' ')"
    fi
    echo -n "."
    sleep 2
  done
  echo -e "\n\nERROR: timeout waiting for pods to come up\n${pods}"
  if [[ -n "${failed_pod}" ]]; then
    echo -e "\n\nFailed Pod (data in YAML format) - ${failed_pod}\n"
    kubectl -n $1 get pods "${failed_pod}" -oyaml
    echo -e "\n\nPod Logs\n"
    kubectl -n $1 logs "${failed_pod}" --all-containers
  fi
  return 1
}

function echo_input_variables() {
  echo "HYPERFOIL_SERVER_URL: ${HYPERFOIL_SERVER_URL}"
  echo "KNATIVE_MANIFESTS: ${KNATIVE_MANIFESTS}"
  echo "TEST_CASE: ${TEST_CASE}"
  echo "TEST_CASE_NAMESPACE: ${TEST_CASE_NAMESPACE}"
  echo "WORKER_ONE: ${WORKER_ONE}"
}
