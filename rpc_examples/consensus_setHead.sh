#! /bin/bash

# Exercise the `consensus_setHead` request, inspect the response.
#
# Note: this assumes `jq` is installed.

BLOCK_HASH=$(./rpc_examples/get_genesis_hash.sh)

PARAMS="[$BLOCK_HASH]"

DATA="{\"jsonrpc\":\"2.0\",\"method\":\"consensus_setHead\",\"params\":$PARAMS,\"id\":42}"

echo Request:
echo $DATA | jq
echo
echo Response:

curl \
	-s \
	-X \
	POST \
	-H "Content-Type: application/json" \
	--data "$DATA" \
	http://localhost:8500 \
	| \
	jq
