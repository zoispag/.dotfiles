#!/usr/bin/env bash

# Open a TablePlus connection to a MySQL database running in a Kubernetes cluster
# Usage: k8stp <namespace> [<localport>]
#   namespace: The Kubernetes namespace where the MySQL deployment is running
#   localport: The local port to forward the MySQL service to (default: random port)
#
# Example: k8stp my-namespace 3306

function k8stp() {
	set -e

	function getUnusedPort {
		local port

		while
			port=$(shuf -n 1 -i 49152-65535)
			netstat -atun | grep -q "$port"
		do
			continue
		done

		echo "$port"
	}

	# Check namespace existence
	namespace="$1"
	context=$(kubectl config current-context)
	kubectl get ns "$namespace" > /dev/null 2>&1 || (echo "Namespace \"$namespace\" not found in \"$context\"" && exit 1)

	# Check MySQL deployment existence
	podscount=$(kubectl get pod \
		--namespace $namespace \
		--selector app.kubernetes.io/name=mysql \
		--no-headers 2> /dev/null | wc -l)
	if [ $podscount -eq 0 ]; then
		echo "MySQL deployment not found in \"$namespace\" (\"$context\")"
		exit 1
	fi

	localport="${2:-$(getUnusedPort)}"

	# Find the MySQL service name
	servicename=$(kubectl get svc \
		--namespace $namespace \
		--selector app.kubernetes.io/name=mysql \
		--output jsonpath='{range .items[?(@.spec.clusterIP != "None")]}{.metadata.name}{end}')

	# Find the MySQL service port
	remoteport=$(kubectl get svc \
		--namespace $namespace \
		--selector app.kubernetes.io/name=mysql \
		--output jsonpath='{range .items[?(@.spec.clusterIP != "None")]}{.spec.ports[0].port}{end}')

	# Retrieve the MySQL password
	databasepassword=$(kubectl get secrets/mysql-credentials \
		--namespace $namespace \
		--output go-template='{{index .data "mysql-password"|base64decode}}'
	)

	# Configure port-forward and get the pid
	kubectl --namespace $namespace port-forward svc/$servicename $localport:$remoteport > /dev/null 2>&1 &
	pid=$!

	# Trap the exit signal to kill the port-forward regardless of how this script exits
	trap '{
		kill $pid
	}' EXIT

	# Wait for $localport to become available
	while ! nc -vz localhost $localport > /dev/null 2>&1 ; do
		sleep 0.1
	done

	# Open connection in TablePlus
	echo "Connecting to database..."
	open -a TablePlus "mysql://kyos:${databasepassword}@127.0.0.1:${localport}?name=MySQL(${context}:${namespace})&env=production/"

	# Keep script running until port-forward is no longer necessary
	echo "Hit [Enter] to exit..."
	read junk
}
