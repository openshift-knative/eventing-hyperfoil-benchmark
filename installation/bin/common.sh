readonly manifests_dir="installation/manifests"
readonly default_manifests="${manifests_dir}/000-subscription-serverless.yaml,${manifests_dir}/000-subscription-hyperfoil.yaml,${manifests_dir}/000-subscription-amq-streams.yaml,${manifests_dir}/100-kafka.yaml,${manifests_dir}/100-hyperfoil.yaml,${manifests_dir}/100-knative-eventing.yaml,${manifests_dir}/100-knative-kafka.yaml"

function create_namespaces {
  echo "Creating namespaces"
  oc create ns knative-eventing --dry-run=client -oyaml | oc apply -f - || return $?
  oc create ns kafka --dry-run=client -oyaml | oc apply -f - || return $?
}

function delete_namespaces {

  # TODO(pierDipi) run must-gather(s) or backup prometheus metrics for further analysis.

  echo "Deleting namespaces"
  oc delete ns kafka --ignore-not-found --timeout=30m || return $?
  oc delete ns knative-eventing --ignore-not-found --timeout=30m || return $?
  if [ -z "${TEST_CASE_NAMESPACE}" ]; then
    oc delete ns "${TEST_CASE_NAMESPACE}" --ignore-not-found --timeout=10m || return $?
  fi
}

function apply_manifests() {
  create_namespaces || return $?

  export KNATIVE_MANIFESTS=${KNATIVE_MANIFESTS-$default_manifests}
  # Extract manifests from the comma-separated list of manifests
  IFS=\, read -ra manifests <<<"${KNATIVE_MANIFESTS}"

  for x in "${manifests[@]}"; do
    echo "Applying ${x}"
    envsubst < "${x}" > oc apply -f - || return $?
    sleep 10
    wait_for_operators_to_be_running || return $?
  done

  wait_for_workloads_to_be_running || exit 1
}

function delete_manifests() {

  export KNATIVE_MANIFESTS=${KNATIVE_MANIFESTS-$default_manifests}
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

function run() {

    oc apply -Rf "${TEST_CASE}/resources" || return $?

    wait_for_resources_to_be_ready "brokers.eventing.knative.dev" || return $?
    wait_for_resources_to_be_ready "triggers.eventing.knative.dev" || return $?
    wait_for_resources_to_be_ready "channels.messaging.knative.dev" || return $?
    wait_for_resources_to_be_ready "subscriptions.messaging.knative.dev" || return $?
    wait_for_resources_to_be_ready "kafkachannels.messaging.knative.dev" || return $?
    wait_for_resources_to_be_ready "kafkasources.sources.knative.dev" || return $?

    # TODO: hyperfoil CLI is interactive and there is no way to use bash directly, expect(1) might help
    # TODO: replace HYPERFOIL_SERVER_URL in hf
    # TODO: inject addressable address
    # hyperfoil connect --insecure "${HYPERFOIL_SERVER_URL}"
    # hyperfoil upload "${TEST_CASE}/hf.yaml"


}

function wait_for_resources_to_be_ready() {
  oc get "${1}" -n "${TEST_CASE_NAMESPACE}" |
    awk '{print $1}' | # Extract resource name
    tail -n +2 | # skip header
    xargs -I{} oc wait "${1}" -n "${TEST_CASE_NAMESPACE}" {} --timeout 300s --for=condition=Ready=True || return $?
}

function wait_for_operators_to_be_running() {
  oc get subscription.operators.coreos.com -n openshift-operators |
    awk '{print $1}' | # Extract resource name
    tail -n +2 | # skip header
    xargs -I{} oc wait subscription.operators.coreos.com -n openshift-operators {} --timeout 300s --for=condition=CatalogSourcesUnhealthy=False || return $?

  oc get csv -n openshift-operators |
    awk '{print $1}' | # Extract resource name
    tail -n +2 | # skip header
    xargs -I{} oc wait csv -n openshift-operators {} --timeout 300s --for=jsonpath='{.status.phase}'=Succeeded || return $?
}

function wait_for_workloads_to_be_running() {
  echo "Waiting for pods to be running"
  sleep 120 # This gives time to dynamic pods to be created.
  wait_until_pods_running "kafka" || return $?
  wait_until_pods_running "knative-eventing" || return $?
}

# Copied from https://github.com/knative/hack/blob/0456e8bf65476e200785565da7c19382e271cae2/library.sh#L215-L265
#
# Waits until all pods are running in the given namespace.
# This function handles some edge cases that `oc wait` does not support,
# and it provides nice debug info on the state of the pod if it failed,
# that’s why we have this long bash function instead of using `oc wait`.
# Parameters: $1 - namespace.
function wait_until_pods_running() {
  echo "Waiting until all pods in namespace $1 are up"
  local failed_pod=""
  for i in {1..150}; do # timeout after 5 minutes
    # List all pods. Ignore Terminating pods as those have either been replaced through
    # a deployment or terminated on purpose.
    local pods
    pods="$(oc get pods --no-headers -n $1 | grep -v Terminating)"
    # All pods must be running (ignore ImagePull error to allow the pod to retry)
    local not_running_pods
    not_running_pods=$(echo "${pods}" | grep -v Running | grep -v Completed | grep -v ErrImagePull | grep -v ImagePullBackOff)
    if [[ -n "${pods}" ]] && [[ -z "${not_running_pods}" ]]; then
      # All Pods are running or completed. Verify the containers on each Pod.
      local all_ready=1
      while read pod; do
        local status
        status=($(echo -n "${pod}" | cut -f2 -d' ' | tr '/' ' '))
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
    oc -n "$1" get pods "${failed_pod}" -oyaml
    echo -e "\n\nPod Logs\n"
    oc -n "$1" logs "${failed_pod}" --all-containers
  fi
  return 1
}
