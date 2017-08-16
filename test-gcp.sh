#!/bin/bash

# pick up gcloud, gsutil
PATH=$PATH:/usr/local/google-cloud-sdk/bin

ID=$1
echo "ID=$ID"

CLUSTER=cluster-ci-$ID
echo "CLUSTER=$CLUSTER"

MASTER=$CLUSTER-m
echo "MASTER=$MASTER"

gcloud --project broad-ctsa dataproc clusters create $CLUSTER --zone us-central1-f --master-machine-type n1-standard-2 --master-boot-disk-size 100 --num-workers 2 --worker-machine-type n1-standard-2 --worker-boot-disk-size 100 --image-version 1.1 --initialization-actions 'gs://hail-dataproc-deps/initialization-actions.sh'

# copy up necessary files
gcloud --project broad-ctsa compute copy-files \
       ./build/libs/hail-all-spark-test.jar \
       ./testng.xml \
       $MASTER:~

gcloud --project broad-ctsa compute ssh $MASTER -- 'mkdir -p src/test'
gcloud --project broad-ctsa compute copy-files \
       ./src/test/resources \
       $MASTER:~/src/test

cat <<EOF | gcloud --project broad-ctsa compute ssh $MASTER -- bash
set -ex

hdfs dfs -mkdir -p src/test
hdfs dfs -rm -r -f -skipTrash src/test/resources
hdfs dfs -put ./src/test/resources src/test

SPARK_CLASSPATH=./hail-all-spark-test.jar \
       spark-submit \
       --class org.testng.TestNG \
       ./hail-all-spark-test.jar \
       ./testng.xml
EOF

gcloud --project broad-ctsa -q dataproc clusters delete --async $CLUSTER

echo "Done!"
