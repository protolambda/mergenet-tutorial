# Mergenet tutorial

Let's set up a local eth1-eth2 merge testnet!

## Pre-requisites install

Note: *Python and Go standard installs assumed*

```shell
# Create, start and install python venv
python -m venv venv 
. venv/bin/activate 
pip install -r requirements.txt

# Install eth2-testnet-genesis tool
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

Configure tranche(s) of validators, edit `eth2_genesis_validators.yaml`.
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

### Start Eth1 nodes

#### Catalyst

Download and install deps:
```shell
git clone https://github.com/ethereum/go-ethereum.git clients/catalyst
cd clients/catalyst
go build -o ./build/bin/catalyst ./cmd/geth
cd ../..
```

Prepare chaindata:
```shell
mkdir -p "$TESTNET_NAME/nodes/catalyst0/chaindata"
./clients/catalyst/build/bin/catalyst --datadir "./$TESTNET_NAME/nodes/catalyst0/chaindata" init "./$TESTNET_NAME/public/eth1_config.json"
```

Run:
```shell
# block proposal rewards/fees go to the below 'etherbase', change it if you like to spend them
./clients/catalyst/build/bin/catalyst --catalyst --rpc --rpcapi net,eth,consensus --nodiscover \
  --miner.etherbase 0x1000000000000000000000000000000000000000 --datadir "./$TESTNET_NAME/nodes/catalyst0/chaindata"
```

#### Nethermind

Work in progress.

### Start Eth2 beacon nodes

#### Teku

Install (assumes openjdk 15+ is installed):
```shell
git clone -b rayonism-merge https://github.com/txrx-research/teku.git clients/teku
cd clients/teku
./gradlew installDist
cd ../..
```

Run (omit the `--validator-keys` if you prefer the stand-alone Teku validator-client mode):
```shell
mkdir -p "./$TESTNET_NAME/nodes/teku0/beacondata"
./clients/teku/build/install/teku/bin/teku \
  --network "./$TESTNET_NAME/public/eth2_config.yaml" \
  --data-path "./$TESTNET_NAME/nodes/teku0/beacondata" \
  --p2p-enabled=false \
  --initial-state "./$TESTNET_NAME/public/genesis.ssz" \
  --eth1-endpoint http://127.0.0.1:8545 \
  --metrics-enabled=true --metrics-interface=127.0.0.1 --metrics-port=8008 \
  --p2p-discovery-enabled=false \
  --p2p-peer-lower-bound=0 \
  --p2p-port=9000 \
  --rest-api-enabled=true \
  --rest-api-docs-enabled=true \
  --rest-api-interface=127.0.0.1 \
  --rest-api-port=5051 \
  --Xdata-storage-non-canonical-blocks-enabled=true \
  --validator-keys "./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/teku-keys:./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/teku-secrets"
```

Note:
- `--p2p-discovery-enabled=false` to disable Discv5, to not advertise your local network to any external discv5 node.
- `--p2p-static-peers` for multi-addr list (comma separated) to other eth2 nodes
- `--p2p-discovery-bootnodes` for ENR list (comma separated), if working with discovery, public net etc.
- `--Xdata-storage-non-canonical-blocks-enabled` is added to store non-canonical blocks for debugging purposes.

#### Prysm

For now, Prysm provides instructions for building from source, but in the future can provide binaries and Docker containers for the merge testnet.

Required dependencies:

- UNIX operating system
- The latest release of [Bazel](https://docs.bazel.build/versions/4.0.0/install.html) installed
- The `cmake` package installed
- The git package installed
- `libssl-dev` installed
- `libgmp-dev` installed 
- `libtinfo5` installed

Then, clone the repo and checkout the branch

```shell
git clone -b merge https://github.com/prysmaticlabs/prysm.git clients/prysm && cd clients/prysm
```

Build the beacon node and validator

```shell
bazel build //beacon-chain:beacon-chain
bazel build //validator:validator
```

Run the beacon node

```shell
bazel run //beacon-chain --define=ssz=minimal -- \
 --datadir="./$TESTNET_NAME/nodes/prysm0/beacondata" \
 --min-sync-peers=0 \
 --http-web3provider=http://127.0.0.1:8545 \
 --bootstrap-node= \
 --chain-config-file="./$TESTNET_NAME/public/eth2_config.yaml" \
 --genesis-state="./$TESTNET_NAME/public/genesis.ssz" \
 --force-clear-db \
 --minimal-config
```

### Start Eth2 validators

#### Teku

If you include `--validator-keys` in the beacon node, it will run a validator-client as part of the node, and **you do not have to run a separate validator**.

However, if you want to run a separate validator client, use:

```shell
mkdir -p "./$TESTNET_NAME/nodes/teku0/validatordata"
./clients/teku/build/install/teku/bin/teku validator-client \
  --network "./$TESTNET_NAME/public/eth2_config.yaml" \
  --data-path "./$TESTNET_NAME/nodes/teku0/validatordata" \
  --beacon-node-api-endpoint "http://127.0.0.1:5051" \
--force-clear-db \
  --validator-keys "./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/teku-keys:./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/teku-secrets
```

#### Prysm

```shell
bazel run //validator --define=ssz=minimal -- \
 --wallet-dir="./$TESTNET_NAME/private/valclient0/prysm" \
 --chain-config-file="./$TESTNET_NAME/public/eth2_config.yaml" \
 --force-clear-db \
 --minimal-config
```

#### Lighthouse

Work in progress.


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

