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

kubectl $CONTEXT --v=4 run netshoot-hostmount-$(uuidgen | tr "[:upper:]" "[:lower:]") --overrides='{
	"spec": {
		"hostNetwork": true,
		"nodeName": "'$NODE'",
		"containers": [{
			"args": [
				"/bin/bash", "-c",
			       	"echo 2 > /proc/sys/net/ipv4/conf/eth0/rp_filter"
			],
			"stdin": true,
			"stdinOnce": true,
			"terminationMessagePath": "/dev/termination-log",
			"terminationMessagePolicy": "File",
			"tty": true,
			"securityContext": {
				"allowPrivilegeEscalation": true,
				"privileged": true,
				"runAsUser": 0,
				"capabilities": {
					"add": ["ALL"]
				}
			},
			"name": "netshoot-hostmount",
			"image": "nicolaka/netshoot",
			"volumeMounts": [{
				"mountPath": "/host",
				"name": "host-slash",
				"readOnly": true
			}]
		}],
	        "restartPolicy": "Never",
		"volumes": [{
			"hostPath": {
				"path": "/",
				"type": ""
			},
			"name": "host-slash"
		}]
	}
}' --image nicolaka/netshoot -- /bin/bash


