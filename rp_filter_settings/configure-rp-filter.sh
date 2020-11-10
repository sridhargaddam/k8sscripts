#!/bin/sh

NODES=$(kubectl get nodes -otemplate --template='{{range .items}}{{.metadata.name}} {{end}}')
echo "List of nodes in the cluster: "$NODES

for node in $NODES;
do
    echo "Updating rp_filter to loose mode(2) on Node: "$node
    ./update-rp-filter.sh $node
done    
