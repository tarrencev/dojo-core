#!/bin/bash

# Description:
#   This script contains a set of functions for deploying to starknet via protostar
#   and caching addresses in a deploys.json
# Dependencies:
#   - jq
#

# ensures that a file that keeps track
# of profile x contract -> address is available
ensure_deployment_cache() {
	file=$1

	# Check if the file exists
	if [ ! -f "$file" ]; then
		# Initialize the file as an empty JSON object if it does not exist
		# necessary for JQ update features to work properly
		echo "{}" >"$file"
	fi
}

# evals a protostar command (assumedly with the json flag) and returns the value associated with key of its json output
eval_protostar() {
	cmd=$1
	key=$2

	# Capture the output of the shell command
	output=$(eval "$cmd")

	# Use jq to select the value of the specified key in the output
	value=$(echo "$output" | jq -r ".$key")

	# Return the value
	echo "$value"
}

# updates a nested json key path with a given value
# in our use case we have a PROFILE x CONTRACT path which we associate with a deployment address
update_json_value() {
	key1=$1
	key2=$2
	value=$3
	dest=$4

	echo "$contract_name deployed to $profile at $value"
	# Use jq to update the value of the nested key in the JSON file
	jq ".$key1.$key2 |= \"$value\"" $dest >$dest.tmp && mv $dest.tmp $dest
}

deploy_protostar() {
	contract_name=$1
	inputs=$2

	class_hash=$(eval_protostar "protostar -p $profile declare \"$build_dir/$contract_name.json\"  --max-fee auto --json" "class_hash")
	deployed_address=$(eval_protostar "protostar -p $profile deploy $class_hash --inputs $inputs --max-fee auto --json" "contract_address")

	echo "$deployed_address"

}
