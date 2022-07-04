#!/bin/bash

CDAP_ENDPOINT=$1
AUTH_TOKEN=$(gcloud auth print-access-token)

# list pipelines and do for each pipeline
PIPELINES=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
    "${CDAP_ENDPOINT}/v3/namespaces/default/apps?artifactName=cdap-data-pipeline" | jq -r '.[] | .name'`

# check all run statuses for all pipelines, and sleep while at least one of them is running
# TODO might need to renew the auth token when it expires
while true; do  # 4
    sleep 1m
    for PIPELINE in $PIPELINES; do # 3
        RUNS=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
            "${CDAP_ENDPOINT}/v3/namespaces/default/apps/${PIPELINE}/workflows/DataPipelineWorkflow/runs" | jq -r '.[] | .status'`
        for STATUS in $RUNS; do # 2
            while grep -q "$STATUS" <<< "PENDING STARTING RUNNING STOPPING"; do # 1
                echo "Waiting as $PIPELINE is $STATUS"
                continue 4
            done
        done
    done
    break
done

# all pipelines have finished, let's see if any of them failed
for PIPELINE in $PIPELINE; do
    RUNS=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "${CDAP_ENDPOINT}/v3/namespaces/default/apps/${PIPELINE}/workflows/DataPipelineWorkflow/runs" | jq -r '.[] | .status'`
    # this shouldn't matter as by design there should be only single run per pipeline, but
    # might need to look at only the latest one to make it more reliable
    for STATUS in $RUNS; do
        if grep -q "$STATUS" <<< "FAILED KILLED REJECTED"; then
            echo "Pipeline $PIPELINE has status: $STATUS"
            exit 1
        fi
    done
done

echo "All good"

