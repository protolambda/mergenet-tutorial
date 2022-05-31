# DEPRECATED

Warning: this repository is outdated. Please refer to the official documentation of each of the ethereum clients to join a testnet.

# Mergenet tutorial

Let's set up a local eth1-eth2 merge testnet!

## Preparing the setup environment

In this tutorial, we use a series of scripts to generate configuration
files, and these scripts have dependencies that we need to
install. You can either install these dependencies on your host or you
can run those scripts inside a docker container. We call this
environment setupenv.

Preparing the setup environment on your host:
```shell
apt-get install python3-dev python3-pip python3-venv golang

# Check that you have Go 1.16+ installed
go version

# Create, start and install python venv
python -m venv venv 
. venv/bin/activate
pip install -r requirements.txt

# Install eth2-testnet-genesis tool (Go 1.16+ required)
go install github.com/protolambda/eth2-testnet-genesis@latest
# Install eth2-val-tools
go install github.com/protolambda/eth2-val-tools@latest
# You are now in the right directory to run the setupenv commands below.
```

Alternatively, you can use docker:
```shell
docker build -t setupenv .
docker run -i -v $PWD:/mergenet-tutorial \
  -v /etc/passwd:/etc/passwd -h setupenv \
  -u $(id -u):$(id -g) -t setupenv \
  /bin/bash
# docker spawns a shell and inside that run:
cd /mergenet-tutorial
# You are now in the right directory to run the setupenv commands below.
```

## Create chain configurations

Set `eth1_genesis_timestamp` inside `mergenet.yaml`to the current
timestamp or a timestamp in the future. To use the current timestamp
run:
```shell
sed -i -e s/GENESIS_TIMESTAMP/$(date +%s)/ mergenet.yaml
```

Otherwise tweak mergenet.yaml as you like. The current default is to
have the Eth2 genesis 10 minutes after the Eth1 genesis.

```shell
# Inside your setupenv: Generate ETH1/ETH2 configs
export TESTNET_NAME="mynetwork"
mkdir -p "$TESTNET_NAME/public" "$TESTNET_NAME/private"
# Configure Eth1 chain
python generate_eth1_conf.py > "$TESTNET_NAME/public/eth1_config.json"
# Configure Eth2 chain
python generate_eth2_conf.py > "$TESTNET_NAME/public/eth2_config.yaml"
```

Configure tranche(s) of validators, edit `genesis_validators.yaml`.
Note: defaults test-purpose mnemonic and configuration is included already, no need to edit for minimal local setup.
Make sure that total of `count` entries is more than the configured `MIN_GENESIS_ACTIVE_VALIDATOR_COUNT` (eth2 config).

## Prepare Eth2 data

Get the tools
[eth2-testnet-genesis](https://github.com/protolambda/eth2-testnet-genesis) and
[eth2-val-tools](https://github.com/protolambda/eth2-val-tools), and then run:

```shell
export VALIDATOR_NODE_NAME="valclient0"
bash ./generate_eth2_validator_data.sh
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

