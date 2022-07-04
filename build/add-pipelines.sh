#!/bin/bash

cat <<EOF > ./cdap/main.tf
# auto-generated
terraform {
    required_providers {
        cdap = {
            source = "GoogleCloudPlatform/cdap"
            version = "0.9.0"
        }
    }
}
EOF

CNT=1
for FILE in ../pipelines/*.json; do
    NAME=`jq '.name' $FILE`
    RESOURCE_ID=`printf "pipeline%03d" $CNT`
    CNT=$((CNT+1))
    cat<<EOF >> ./cdap/main.tf

resource "cdap_application" "$RESOURCE_ID" {
    name = $NAME
    spec = file("\${path.module}/../$FILE")
}
EOF
done