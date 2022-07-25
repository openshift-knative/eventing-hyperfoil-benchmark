#!/usr/bin/env python3

import argparse
import json
import sys

must_fire_alerts = {
    "OpenShiftServerlessEventConsumerThroughput",
    "OpenShiftServerlessEventProducerThroughput",
}

ignore_alerts = {
    "PodDisruptionBudgetAtLimit",
}

namespace = "knative-eventing"

parser = argparse.ArgumentParser(description="Verify openshift alerts")
parser.add_argument('--alerts-filepath', type=str, dest="alerts_filepath", help="Fired alerts file path", required=True)
args = parser.parse_args()

alerts_filepath = args.alerts_filepath

with open(alerts_filepath, "r") as f:
    alerts_response = json.loads(f.read())

print(json.dumps(alerts_response, sort_keys=True, indent=4))
assert alerts_response['status'] == 'success'

alerts = alerts_response['data']

alerts_err = []

for alert in alerts:
    if alert['labels']['namespace'] != namespace:
        continue

    alert_name = alert['labels']['alertname']
    print(f"Found {alert_name} alert in {namespace}")

    if alert_name not in must_fire_alerts:
        alerts_err.append({"unexpected": alert})
        must_fire_alerts.discard(alert_name)

if len(must_fire_alerts) > 0:
    for alert in must_fire_alerts:
        alerts_err.append({"expected": alert})

if len(alerts_err) > 0:
    print()
    print(f"Found unexpected alerts in namespace {namespace}")
    print(json.dumps(alerts_err, sort_keys=True, indent=4))
    sys.exit(1)
