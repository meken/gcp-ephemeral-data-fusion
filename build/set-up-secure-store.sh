#!/bin/bash

CDAP_ENDPOINT=$1
AUTH_TOKEN=$(gcloud auth print-access-token)

# copy all secrets from Secret Manager to the new CDAP instance
SECRET_NAMES=`gcloud secrets list --format="value(name)"`
for SECRET in $SECRET_NAMES; do
    SECRET_VALUE=`gcloud secrets versions access latest --secret=$SECRET`
    BODY=$(jq -n --arg data "$SECRET_VALUE" '$ARGS.named')
    curl -s -X PUT -H "Authorization: Bearer ${AUTH_TOKEN}" -d "$BODY" \
       "${CDAP_ENDPOINT}/v3/namespaces/default/securekeys/${SECRET}"
done