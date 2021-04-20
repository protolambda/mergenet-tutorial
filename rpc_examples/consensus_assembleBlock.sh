#! /bin/bash

# Exercise the `consensus_newBlock` request, inspect the response.
#
# Note: this assumes `jq` is installed.


curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x1b4", true],"id":1}'

PARENT_HASH=$(./get_genesis_hash.sh)
TIMESTAMP=$(printf 0x%02x $(date +%s))

PARAMS="[{ \"parentHash\": $PARENT_HASH, \"timestamp\": \"$TIMESTAMP\"}]"

DATA="{\"jsonrpc\":\"2.0\",\"method\":\"consensus_assembleBlock\",\"params\":$PARAMS,\"id\":42}"

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
	http://localhost:8545 \
	| \
	jq
