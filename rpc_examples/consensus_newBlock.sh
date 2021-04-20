#! /bin/bash

# Exercise the `consensus_assembleBlock` request, inspect the response.
#
# Note: this assumes `jq` is installed.

PARENT_HASH=$(./get_genesis_hash.sh)
TIMESTAMP=$(printf 0x%02x $(date +%s))
PARAMS="[{ \"parentHash\": $PARENT_HASH, \"timestamp\": \"$TIMESTAMP\"}]"
DATA="{\"jsonrpc\":\"2.0\",\"method\":\"consensus_assembleBlock\",\"params\":$PARAMS,\"id\":42}"

EXECUTION_PAYLOAD=$(curl \
	-s \
	-X \
	POST \
	-H "Content-Type: application/json" \
	--data "$DATA" \
	http://localhost:8545 \
	| \
	jq \
	-c \
	'.["result"]')

DATA="{\"jsonrpc\":\"2.0\",\"method\":\"consensus_newBlock\",\"params\":[$EXECUTION_PAYLOAD],\"id\":42}"

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
