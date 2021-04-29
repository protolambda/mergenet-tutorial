#! /bin/bash

# Get the genesis hash via the RPC
#
# Note: this assumes `jq` is installed.

DATA='{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["earliest", true],"id":1}'

curl \
	-s \
	-X \
	POST \
	-H "Content-Type: application/json" \
	--data "$DATA" \
	http://localhost:8545 \
	| \
	jq \
	'.["result"]["hash"]'
