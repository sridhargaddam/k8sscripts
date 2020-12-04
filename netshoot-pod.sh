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

kubectl $CONTEXT --v=4 run netshoot-pod-$(uuidgen) --generator=run-pod/v1 --rm -i --tty --overrides='{
	"spec": {
		"nodeName": "'$NODE'",
		"containers": [{
			"args": [
				"/bin/bash"
			],
			"stdin": true,
			"stdinOnce": true,
			"terminationMessagePath": "/dev/termination-log",
			"terminationMessagePolicy": "File",
			"tty": true,
			"name": "netshoot-pod",
			"image": "nicolaka/netshoot"
		}]
	}
}' --image nicolaka/netshoot -- /bin/bash


