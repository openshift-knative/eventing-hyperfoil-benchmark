

HTTP_TARGET=$(oc get brokers.eventing.knative.dev -n "${TEST_CASE_NAMESPACE}" p1-r1-unord-b1-t1-32kb-sasl-passwd-0 -o jsonpath='{.status.address.url}') || exit 1
BENCHMARK_NAME=eventing-staircase

export HTTP_TARGET BENCHMARK_NAME

