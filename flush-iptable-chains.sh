#!/bin/sh
NODE=$1
if [[ "$CONTEXT" != "" ]]; then
  CONTEXT="--context ${CONTEXT}"
fi

if [[ x"$NODE" == x ]]; then
  echo please provide a node name as the first argument
  echo ""
  kubectl $CONTEXT get nodes -o wide
  echo ""
  echo "submariner gws:"
  echo ""
  kubectl $CONTEXT get nodes -o wide -l submariner.io/gateway=true
  exit 1
fi

NODES=$(kubectl $CONTEXT get nodes -o wide -l submariner.io/gateway=true)
echo $NODES
