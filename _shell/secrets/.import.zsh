#!/usr/bin/env bash

# Import Environment variables stored in a 1Password account
# By default, it will use the `my.1password.com` account
# If you want to use a different account,
#   simply provide the account name as the first argument
#
# Examples:
# - `$ importEnv`
# - `$ importEnv foo`
#
# Inspired by https://grantorchard.com/securing-environment-variables-with-1password/

function importEnv() {
	local opaccount=${1:-my}

	# Login to 1Password.
	# Assumes you have installed the OP CLI
	# For more details see https://developer.1password.com/docs/cli/get-started#install

	# An 1password entry with name Environment Variables needs to be set
	#  and all variables must be set in a single section with name 'ENTRIES'. Label will be used
	#  as the export key and value as its value.
	local res=$(op --account "$opaccount" item get "Environment Variables" --format json)

	# Convert to base64 for multi-line secrets.
	# We only keep the label and the value keys from the json object of 1password field schema.
	for row in $(echo "${res}" | jq -r -r '.fields[] | select(.section.label=="ENTRIES") | {label: .label, value: .value} | @base64'); do
		_evalJq() {
			echo "${row}" | base64 --decode | jq -r "$1"
		}
		local name=$(_evalJq .label)
		local value=$(_evalJq .value)

		echo "* Setting environment variable ${name}"
		export $(echo "${name}=${value}")
	done
}
