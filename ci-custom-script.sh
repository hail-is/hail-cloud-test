#!/bin/bash
ID=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 12)
CLUSTER=cluster-ci-$ID

echo ID=$ID
echo CLUSTER=$CLUSTER

bash /home/ec2-user/test-gcp.sh $ID %env.DATAPROC_VERSION%

/usr/local/google-cloud-sdk/bin/gcloud --project broad-ctsa -q dataproc clusters delete --async $CLUSTER || true
