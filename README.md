# Mergenet tutorial

Let's set up a local eth1-eth2 merge testnet!

## Pre-requisites install

Note: *Python (incl. `python-dev`) and Go (1.16+) standard installs assumed*

```shell
# Create, start and install python venv
python -m venv venv 
. venv/bin/activate
pip install -r requirements.txt

# Install eth2-testnet-genesis tool (Go 1.16+ required)
go install github.com/protolambda/eth2-testnet-genesis@latest
# Install eth2-val-tools
go install github.com/protolambda/eth2-val-tools@latest
```

## Create chain configurations

Tweak `mergenet.yaml` as you like.

Get current timestamp as eth1 genesis timestamp, then change the eth2-genesis delay to offset the chain start:
```shell
date +%s
```

```shell
# Create output
export TESTNET_NAME="mynetwork"
mkdir "$TESTNET_NAME"
mkdir "$TESTNET_NAME/public"
mkdir "$TESTNET_NAME/private"
# Configure Eth1 chain
python generate_eth1_conf.py > "$TESTNET_NAME/public/eth1_config.json"
# Configure Eth2 chain
python generate_eth2_conf.py > "$TESTNET_NAME/public/eth2_config.yaml"
```

Configure tranche(s) of validators, edit `genesis_validators.yaml`.
Note: defaults test-purpose mnemonic and configuration is included already, no need to edit for minimal local setup.
Make sure that total of `count` entries is more than the configured `MIN_GENESIS_ACTIVE_VALIDATOR_COUNT` (eth2 config).

## Prepare Eth2 data
```shell
# Generate Genesis Beacon State
eth2-testnet-genesis merge \
  --eth1-config "$TESTNET_NAME/public/eth1_config.json" \
  --eth2-config "$TESTNET_NAME/public/eth2_config.yaml" \
  --mnemonics genesis_validators.yaml \
  --state-output "$TESTNET_NAME/public/genesis.ssz" \
  --tranches-dir "$TESTNET_NAME/private/tranches"

# Build validator keystore for nodes
#
# Prysm likes to consume bundled keystores. Use `--prysm-pass` to encrypt the bundled version.
# For the other eth2 clients, a different secret is generated per validator keystore.
#
# You can change the range of validator accounts, to split keys between nodes.
# The mnemonic and key-range should match that of a tranche of validators in the beacon-state genesis.
export VALIDATOR_NODE_NAME="valclient0"
eth2-val-tools keystores \
  --out-loc "$TESTNET_NAME/private/$VALIDATOR_NODE_NAME" \
  --prysm-pass="foobar" \
  --source-min=0 \
  --source-max=64 \
  --source-mnemonic="lumber kind orange gold firm achieve tree robust peasant april very word ordinary before treat way ivory jazz cereal debate juice evil flame sadness"
```

## Start nodes

This documents how to build the binaries from source, so you can make changes and check out experimental git branches.
It's possible to build docker images (or use pre-built ones) as well. Ask the client devs for alternative install instructions.

```shell
mkdir clients

mkdir "$TESTNET_NAME/nodes"
```

You can choose to run clients in two ways:
- [Build and run from source](./from_source.md)
- [Run in docker](./from_docker.md)

The docker instructions include how to configure each of the clients. 
Substitute docker volume-mounts with your own directory layout choices, the instructions are otherwise the same. 


## Genesis

Now wait for the genesis of the chain!
`actual_genesis_timestamp = eth1_genesis_timestamp + eth2_genesis_delay`

## Bonus

### Test ETH transaction

Import a pre-mined account into some web3 wallet (e.g. metamask), connect to local RPC, and send a transaction with a GUI.

Run `example_transaction.py`.

### Test deposit

TODO

### Test contract deployment

TODO

