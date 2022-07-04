#!/bin/bash

export AUTH_TOKEN=$(gcloud auth print-access-token)
export INSTANCE_ID=cdf-sample-ku65
export CDAP_ENDPOINT=$(gcloud beta data-fusion instances describe \
   --location=europe-west4 \
   --format="value(apiEndpoint)" \
    ${INSTANCE_ID})

# list pipelines and do for each pipeline
export PIPELINES=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
    "${CDAP_ENDPOINT}/v3/namespaces/default/apps?artifactName=cdap-data-pipeline" | jq -r '.[] | .name'`

# check all run statuses for all pipelines, and sleep while at least one of them is running
while true; do  # 4
    for PIPELINE in $PIPELINES; do # 3
        RUNS=`curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" \
            "${CDAP_ENDPOINT}/v3/namespaces/default/apps/${PIPELINE}/workflows/DataPipelineWorkflow/runs" | jq -r '.[] | .status'`
        for STATUS in $RUNS; do # 2
            while grep -q "$STATUS" <<< "PENDING STARTING RUNNING STOPPING"; do # 1
                echo "Waiting as $PIPELINE is $STATUS"
                sleep 1m
                continue 4
            done
        done
    done
    break
done

echo "All good"

