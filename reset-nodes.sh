#!/bin/sh

NODES=$(kubectl get nodes -otemplate --template='{{range .items}}{{.metadata.name}} {{end}}')
echo "List of nodes in the cluster: "$NODES

for node in $NODES;
do
    echo "Deleting Submariner rules from the node:: "$node
    podName=reset-node-$(uuidgen)
    kubectl $CONTEXT --v=4 run ${podName} --overrides='{
	"spec": {
		"hostNetwork": true,
		"nodeName": "'$node'",
		"containers": [{
			"args": [
				"/bin/bash", "-c",
			       	"ip xfrm policy flush; ip xfrm state flush; ip link del vx-submariner; ip route flush table 150; iptables -t nat -F SUBMARINER-POSTROUTING;"
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

    while [[ $(kubectl get pods ${podName} -o 'jsonpath={..status.phase}') != "Succeeded" ]]; do echo "Waiting for pod ${podName} to finish..." && sleep 2; done
    kubectl delete pod ${podName}
done    

echo "Restarting Submariner pods..."
kubectl delete pod -l app=submariner-routeagent -n submariner-operator
kubectl delete pod -l app=submariner-gateway -n submariner-operator
