#!/usr/bin/env python3
import argparse
import os

parser = argparse.ArgumentParser(description='Generate a test case')
parser.add_argument('--broker-class', type=str, dest='broker_class', default='Kafka', help='Broker class',
                    choices=['Kafka', 'KafkaNamespaced'])
parser.add_argument('--num-brokers', type=int, dest='num_brokers', help='Number of brokers')
parser.add_argument('--num-triggers', type=int, dest='num_triggers', help='Number of triggers for each broker')
parser.add_argument('--num-partitions', type=int, dest='num_partitions', default=10,
                    help='Number of partitions for Broker\'s topic')
parser.add_argument('--resources-output-dir', type=str, dest='resources_output_dir',
                    help='Output directory for resources')
parser.add_argument('--hf-output-dir', type=str, dest='hf_output_dir',
                    help='Output directory for Hyperfoil benchmark definition')
parser.add_argument('--delivery-order', type=str, dest='delivery_order', help='Delivery order', default='ordered')
parser.add_argument('--name-prefix', type=str, dest='name_prefix', help='Prefix for resource names')
parser.add_argument('--payload-file', type=str, dest='payload_file', help='File path with the payload content')
parser.add_argument('--initial-users-per-sec', type=int, default=10, dest='initial_users_per_sec',
                    help='Initial users per second')
parser.add_argument('--increment-users-per-sec', type=int, default=10, dest='increment_users_per_sec',
                    help='Increment users per second')
parser.add_argument('--sla-mean-response-time-sec', type=int, default=70, dest='sla_mean_response_time_sec',
                    help='Mean response time in seconds')
parser.add_argument('--sla-p999-response-time-sec', type=int, default=90, dest='sla_p999_response_time_sec',
                    help='P999 response time in seconds')
parser.add_argument('--secret-name', type=str, default=None, dest='secret_name', help='auth.secret.ref.name')
parser.add_argument('--bootstrap.servers', type=str, default="my-cluster-kafka-bootstrap.kafka:9092",
                    dest='bootstrap_servers', help='bootstrap.servers')
parser.add_argument('--replication-factor', type=int, default=3,
                    dest='replication_factor', help='default.topic.replication.factor')
parser.add_argument('--initial-ramp-up-duration', type=int, default=60,
                    dest='initial_ramp_up_duration', help='initialRampUpDuration in sec')
parser.add_argument('--ramp-up-duration', type=int, default=120,
                    dest='ramp_up_duration', help='ramp_up_duration in sec')
parser.add_argument('--steady_state-duration', type=int, default=300,
                    dest='steady_state_duration', help='steady_state_duration in sec')
parser.add_argument('--max-iterations', type=int, default=5,
                    dest='max_iterations', help='max_iterations')
parser.add_argument('--receiver-fault-min-sleep-duration', type=str, default='',
                    dest='receiver_fault_min_sleep_duration', help='receiver_fault_min_sleep_duration')
parser.add_argument('--receiver-fault-max-sleep-duration', type=str, default='',
                    dest='receiver_fault_max_sleep_duration', help='receiver_fault_max_sleep_duration')
args = parser.parse_args()

triggers = []
brokers = []

os.makedirs(args.hf_output_dir, mode=0o777, exist_ok=True)
os.makedirs(args.resources_output_dir, mode=0o777, exist_ok=True)

serviceName = args.name_prefix + "-svc"

secret_config = f"auth.secret.ref.name: {args.secret_name}" if args.secret_name else ""

for b_idx in range(args.num_brokers):
    broker_name = f"{args.name_prefix}-{b_idx}"
    brokers.append(broker_name)
    broker_manifests = f"""
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {broker_name}-config
data:
  default.topic.partitions: "{args.num_partitions}"
  default.topic.replication.factor: "{args.replication_factor}"
  bootstrap.servers: {args.bootstrap_servers}
  {secret_config}
---
apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
  annotations:
    eventing.knative.dev/broker.class: {args.broker_class}
  name: {broker_name}
spec:
  # Configuration specific to this broker.
  config:
    apiVersion: v1
    kind: ConfigMap
    name: {broker_name}-config
  delivery:
    retry: 12
    backoffPolicy: exponential
    backoffDelay: PT0.2S
---
"""
    filename = f"{args.resources_output_dir}/{broker_name}.yaml"
    print(f"Saving file {filename}")
    with open(filename, "w") as f:
        f.write(broker_manifests)

    for t_idx in range(args.num_triggers):
        trigger_name = f"{broker_name}-trigger-{t_idx}"
        triggers.append(trigger_name)
        fault = ""
        if args.receiver_fault_max_sleep_duration != '' and args.receiver_fault_min_sleep_duration != '':
            fault = f"""
      fault:
        minSleepDuration: {args.receiver_fault_min_sleep_duration}
        maxSleepDuration: {args.receiver_fault_max_sleep_duration}"""

        trigger_manifests = f"""
---
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: {trigger_name}
  annotations:
    kafka.eventing.knative.dev/delivery.order: {args.delivery_order}
spec:
  broker: {broker_name}
  subscriber:
    ref:
      apiVersion: v1
      kind: Service
      name: {serviceName}
    uri: "/{trigger_name}"
---
apiVersion: v1
kind: Service
metadata:
  name: {serviceName}
  labels:
    app: {serviceName}
spec:
  type: ClusterIP
  selector:
    app: {serviceName}
  ports:
    - port: 80
      protocol: TCP
      targetPort: receiver
      name: http
    - port: 9090
      protocol: TCP
      targetPort: http-metrics
      name: http-metrics

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-sacura
data:
  sacura.yaml: |
    sender:
      disabled: true
    receiver:
      port: 8080
      timeout: 5m
      maxDuplicatesPercentage: 1{fault}
    duration: 10m
    timeout: 1m

---

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {serviceName}
  labels:
    app: {serviceName}
spec:
  endpoints:
    - path: /metrics
      port: http-metrics
  selector:
    matchLabels:
      app: {serviceName}
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {serviceName}
  labels:
    app: {serviceName}
spec:
  selector:
    matchLabels:
      app: {serviceName}
  template:
    metadata:
      labels:
        app: {serviceName}
    spec:
      containers:
        - name: receiver
          image: ghcr.io/pierdipi/sacura/sacura-7befbbbc92911c6727467cfbf23af88f
          args:
            - "--config"
            - "/etc/sacura/sacura.yaml"
          imagePullPolicy: Always
          resources:
            requests:
              memory: "1Gi"
              cpu: "1"
          volumeMounts:
          - mountPath: /etc/sacura
            name: config
          ports:
            - containerPort: 8080
              protocol: TCP
              name: receiver
            - containerPort: 9090
              protocol: TCP
              name: http-metrics
          env:
            - name: OTEL_RESOURCE_ATTRIBUTES
              value: "service={serviceName}"
            - name: OTEL_SERVICE_NAME
              value: "sacura"
      volumes:
      - name: config
        configMap:
          name: config-sacura

"""
        filename = f"{args.resources_output_dir}/{trigger_name}.yaml"
        print(f"Saving file {filename}")
        with open(filename, "w") as f:
            f.write(trigger_manifests)

customSLAs = ""
scenarios = ""

for trigger_name in triggers:
    customSLAs += f"""
    e2elatency-{trigger_name}:
      - errorRatio: 0
        limits:
          "0.999": "30s"
        meanResponseTime: 10s
      - meanResponseTime: 10s
        window: 60s

"""

with open(args.payload_file) as f:
    payload = f.read().replace("\n", "")

for broker_name in brokers:
    scenarios += f"""
    - {broker_name}:
        - timestamp:
            toVar: eventTimestamp
        - httpRequest:
            POST: /${{TEST_CASE_NAMESPACE}}/{broker_name}
            body: "{payload}"
            headers:
              ce-benchmarktimestamp: "${{eventTimestamp}}"
              ce-id: abc
              ce-metric: e2elatency
              ce-phase: "${{hyperfoil.phase.id}}"
              ce-phasestart: "${{hyperfoil.phase.start.time.as.string}}"
              ce-runid: "${{hyperfoil.run.id}}"
              ce-source: "http://hyperfoil-bench.com"
              ce-specversion: "1.0"
              ce-type: datapoint.hyperfoilbench
              content-type: application/json
            sla:
              - meanResponseTime: {args.sla_mean_response_time_sec}s
              - limits:
                  "0.999": {args.sla_p999_response_time_sec}s

"""

hf_manifest = f"""
name: eventing-staircase
agents:
  agent-one:
    node: ${{WORKER_ONE}}
    stop: true
  agent-two:
    node: ${{WORKER_ONE}}
    stop: true
  agent-three:
    node: ${{WORKER_ONE}}
    stop: true
http:
  host: ${{HTTP_HOST}}
  sharedConnections: 21000
staircase:
  initialRampUpDuration: {args.initial_ramp_up_duration}s
  initialUsersPerSec: {args.initial_users_per_sec}
  incrementUsersPerSec: {args.increment_users_per_sec}
  steadyStateDuration: {args.steady_state_duration}s
  maxIterations: {args.max_iterations}
  maxSessions: 20000
  rampUpDuration: {args.ramp_up_duration}s
  scenario:
{scenarios}
"""

with open(f"{args.hf_output_dir}/hf.yaml", "w") as f:
    f.write(hf_manifest)

additional_script = f"""

HTTP_TARGET=$(oc get brokers.eventing.knative.dev -n "${{TEST_CASE_NAMESPACE}}" {brokers[0]} -o jsonpath='{{.status.address.url}}') || exit 1
BENCHMARK_NAME=eventing-staircase

export HTTP_TARGET BENCHMARK_NAME

"""

with open(f"{args.hf_output_dir}/additional.sh", "w") as f:
    f.write(additional_script)
