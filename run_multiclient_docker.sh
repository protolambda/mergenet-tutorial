#!/bin/bash

# To clean up:
# docker stop bootnode0 catalyst0 besu0 nethermind0 teku0bn teku0vc lighthouse0bn lighthouse0vc prysm0bn prysm0vc forkmon0 postgres0 explorer0
# docker container prune
# sudo rm -rf testnets/$TESTNET_NAME

set -e

# mainnet or minimal. For mainnet, you need `2**14` validators. For minimal just 64
ETH2_SPEC_VARIANT=minimal

# LIGHTHOUSE_DOCKER_IMAGE=sigp/lighthouse:rayonism
# Built with portable,spec-minimal features,
# so the image can be used everywhere, and the minimal config can be used for testing
LIGHTHOUSE_DOCKER_IMAGE=protolambda/lighthouse:rayonism

TEKU_DOCKER_IMAGE=mkalinin/teku:rayonism

#PRYSM_BEACON_IMAGE=gcr.io/prysmaticlabs/prysm/beacon-chain:merge-mainnet
#PRYSM_VALIDATOR_IMAGE=gcr.io/prysmaticlabs/prysm/validator:merge-mainnet
PRYSM_BEACON_IMAGE=protolambda/prysm-beacon:rayonism
PRYSM_VALIDATOR_IMAGE=protolambda/prysm-validator:rayonism

NIMBUS_DOCKER_IMAGE=protolambda/nimbus:rayonism

# Eth1 nodes
NETHERMIND_IMAGE=nethermind/nethermind:latest
GETH_IMAGE=ethereum/client-go:latest
BESU_IMAGE=suburbandad/besu:rayonism

# Tools
BOOTNODE_IMAGE=protolambda/eth2-bootnode:latest
FORKMON_IMAGE=protolambda/eth2-fork-mon:latest
POSTGRES_IMAGE=postgres:12.0
EXPLORER_IMAGE=protolambda/merge-explorer:latest

EXPLORER_TABLES_SQL_PATH=$(readlink -f ../eth2-beaconchain-explorer/tables.sql)
if test -f "$EXPLORER_TABLES_SQL_PATH"; then
  echo "Found SQL tables, enabling block explorer"
else
  echo "No block explorer enabled, need SQL tables definition"
  exit 1
fi


# TODO: not yet working. Nimbus requires custom docker builds for testnet configuration changes
# (need a nimbus dev to look at this)
NIMBUS_ENABLED=0

if [ "$ETH2_SPEC_VARIANT" == "minimal" ]; then
#  PRYSM_BEACON_IMAGE=gcr.io/prysmaticlabs/prysm/beacon-chain:merge-minimal
#  PRYSM_VALIDATOR_IMAGE=gcr.io/prysmaticlabs/prysm/validator:merge-minimal
  PRYSM_BEACON_IMAGE=protolambda/prysm-beacon:rayonism-minimal
  PRYSM_VALIDATOR_IMAGE=protolambda/prysm-validator:rayonism-minimal
  # TODO: failed attempt at nimbus minimal build. Need to try configure testnet for minimal-mode config outside of docker.
  NIMBUS_DOCKER_IMAGE=protolambda/nimbus:rayonism-minimal
fi

VALIDATORS_MNEMONIC="lumber kind orange gold firm achieve tree robust peasant april very word ordinary before treat way ivory jazz cereal debate juice evil flame sadness"
ETH1_MNEMONIC="enforce patient ridge volume question system myself moon world glass later hello tissue east chair suspect remember check chicken bargain club exit pilot sand"
PRYSM_BULK_KEYSTORE_PASS="foobar"

# Ensure necessary env vars are present.
if [ -z "$TESTNET_NAME" ]; then
    echo TESTNET_NAME is not set, exiting
    exit 1
fi

TESTNET_PATH="${PWD}/testnets/$TESTNET_NAME"
mkdir -p "$TESTNET_PATH"

# Pull client images
docker pull $LIGHTHOUSE_DOCKER_IMAGE
docker pull $TEKU_DOCKER_IMAGE
docker pull $PRYSM_BEACON_IMAGE
docker pull $PRYSM_VALIDATOR_IMAGE
docker pull $NETHERMIND_IMAGE
docker pull $GETH_IMAGE
docker pull $BESU_IMAGE

# Basic testnet tooling
docker pull $BOOTNODE_IMAGE
docker pull $FORKMON_IMAGE

# Block Explorer
docker pull $POSTGRES_IMAGE
docker pull $EXPLORER_IMAGE


if [ $NIMBUS_ENABLED != 0 ]; then
  docker pull $NIMBUS_DOCKER_IMAGE
fi

# Create venv for scripts
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt

# Configure testnet
mkdir -p "$TESTNET_PATH/public"
mkdir -p "$TESTNET_PATH/private"
mkdir -p "$TESTNET_PATH/nodes"

# Starting bootnode
echo "starting discv5 bootnode"
NODE_NAME=bootnode0
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name "$NODE_NAME" \
  --rm \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/data" \
  --net host \
  -itd $BOOTNODE_IMAGE \
  --api-addr "0.0.0.0:10000" \
  --enr-ip "127.0.0.1" \
  --enr-udp "11000" \
  --listen-ip "0.0.0.0" \
  --listen-udp "11000" \
  --node-db "/data" \
  --priv="c481fa289efe87b258365f057e6c3afa51dbbbf31d9c38246b36d0a48da326ee"

# you can fetch this from `http://localhost:10000/enr"
BOOTNODE_ENR="enr:-Ku4QOhH76YiJtgBrVBAmiotsLxS9lpdxbtYkpTdLen7CZCyTMCjcSuwcRnFggwn-IHbSEL2RC6kC-2BUHBf5yiVI3sBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpD1pf1CAAAAAP__________gmlkgnY0gmlwhH8AAAGJc2VjcDI1NmsxoQN0nREs-mofKzp_XQ1M1xFrOkr9gMMgCdLFbvH7aPQHT4N1ZHCCKvg"

echo "Preparing keystores"

eth2-val-tools keystores \
  --out-loc "$TESTNET_PATH/private/validator0" \
  --prysm-pass="$PRYSM_BULK_KEYSTORE_PASS" \
  --source-min=0 \
  --source-max=22 \
  --source-mnemonic="$VALIDATORS_MNEMONIC"

eth2-val-tools keystores \
  --out-loc "$TESTNET_PATH/private/validator1" \
  --prysm-pass="$PRYSM_BULK_KEYSTORE_PASS" \
  --source-min=22 \
  --source-max=44 \
  --source-mnemonic="$VALIDATORS_MNEMONIC"

eth2-val-tools keystores \
  --out-loc "$TESTNET_PATH/private/validator2" \
  --prysm-pass="$PRYSM_BULK_KEYSTORE_PASS" \
  --source-min=44 \
  --source-max=64 \
  --source-mnemonic="$VALIDATORS_MNEMONIC"

# TODO: split in 4 instead, so nimbus can have keys.

TIME_NOW=$(date +%s)
# 60 seconds to start all containers and get them connected.
GENESIS_DELAY=60
ETH1_GENESIS_TIMESTAMP=$((TIME_NOW + GENESIS_DELAY))
ETH2_GENESIS_DELAY=0
ETH2_GENESIS_TIMESTAMP=$((ETH1_GENESIS_TIMESTAMP + ETH2_GENESIS_DELAY))

echo "configuring testnet...
Eth1 genesis: $TIME_NOW (now) + $GENESIS_DELAY (delay) = $ETH1_GENESIS_TIMESTAMP
Eth2 genesis: $ETH1_GENESIS_TIMESTAMP (eth1) + $ETH2_GENESIS_DELAY (eth2 delay) = $ETH2_GENESIS_TIMESTAMP"

cat > "$TESTNET_PATH/private/mergenet.yaml" << EOT
mnemonic: ${ETH1_MNEMONIC}
eth1_premine:
  "m/44'/60'/0'/0/0": 10000000ETH
  "m/44'/60'/0'/0/1": 10000000ETH
  "m/44'/60'/0'/0/2": 10000000ETH
chain_id: 700
deposit_contract_address: "0x4242424242424242424242424242424242424242"
# either 'minimal' or 'mainnet'
eth2_base_config: ${ETH2_SPEC_VARIANT}
eth2_fork_version: "0x00000700"
eth1_genesis_timestamp: ${ETH1_GENESIS_TIMESTAMP}
# Tweak this. actual_genesis_timestamp = eth1_genesis_timestamp + eth2_genesis_delay
eth2_genesis_delay: ${ETH2_GENESIS_DELAY}
EOT


echo "configuring chains"
# Configure Eth1 chain
python generate_eth1_conf.py "$TESTNET_PATH/private/mergenet.yaml" > "$TESTNET_PATH/public/eth1_config.json"
# Configure Eth1 chain for Nethermind
python generate_eth1_nethermind_conf.py "$TESTNET_PATH/private/mergenet.yaml" > "$TESTNET_PATH/public/eth1_nethermind_config.json"
# Configure Eth2 chain
python generate_eth2_conf.py "$TESTNET_PATH/private/mergenet.yaml" > "$TESTNET_PATH/public/eth2_config.yaml"

echo "configuring genesis validators"
cat > "$TESTNET_PATH/private/genesis_validators.yaml" << EOT
# a 24 word BIP 39 mnemonic
- mnemonic: "${VALIDATORS_MNEMONIC}"
  count: 64  # 64 for minimal config, 16384 for mainnet config
EOT

echo "generating genesis BeaconState"
eth2-testnet-genesis merge \
  --eth1-config "$TESTNET_PATH/public/eth1_config.json" \
  --eth2-config "$TESTNET_PATH/public/eth2_config.yaml" \
  --mnemonics "$TESTNET_PATH/private/genesis_validators.yaml" \
  --state-output "$TESTNET_PATH/public/genesis.ssz" \
  --tranches-dir "$TESTNET_PATH/private/tranches"

echo "preparing geth initial state"
NODE_NAME=catalyst0
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name "$NODE_NAME" \
  --rm \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/gethdata" \
  -v "$TESTNET_PATH/public/eth1_config.json:/networkdata/eth1_config.json" \
  --net host \
  $GETH_IMAGE \
  --catalyst \
  --datadir "/gethdata/chaindata" \
  init "/networkdata/eth1_config.json"

# Run eth1 nodes

# Go-ethereum
# Note: networking is disabled on Geth in merge mode (at least for now)
echo "starting geth node"
NODE_NAME=catalyst0
docker run \
  --name "$NODE_NAME" \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/gethdata" \
  -itd $GETH_IMAGE \
  --catalyst \
  --http --http.api net,eth,consensus \
  --http.port 8500 \
  --http.addr 0.0.0.0 \
  --http.corsdomain "*" \
  --ws --ws.api net,eth,consensus \
  --ws.port 8600 \
  --ws.addr 0.0.0.0 \
  --port 30303 \
  --nodiscover \
  --miner.etherbase 0x1000000000000000000000000000000000000000 \
  --datadir "/gethdata/chaindata"

# Nethermind
# Note: networking is active, the transaction pool propagation is active on nethermind
echo "starting nethermind node"
NODE_NAME=nethermind0
# Note: unfortunately, running nethermind as non-root user in docker is a pain
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name $NODE_NAME \
  --net host \
  -v "$TESTNET_PATH/public/eth1_nethermind_config.json:/networkdata/eth1_nethermind_config.json" \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/netherminddata" \
  -itd $NETHERMIND_IMAGE \
  -c catalyst \
  --datadir "/netherminddata" \
  --Init.ChainSpecPath "/networkdata/eth1_nethermind_config.json" \
  --Init.WebSocketsEnabled true \
  --JsonRpc.Enabled true \
  --JsonRpc.EnabledModules "net,eth,consensus" \
  --JsonRpc.Port 8501 \
  --JsonRpc.WebSocketsPort 8601 \
  --JsonRpc.Host 0.0.0.0 \
  --Network.DiscoveryPort 30301 \
  --Network.P2PPort 30301 \
  --Merge.BlockAuthorAccount 0x1000000000000000000000000000000000000000

# Besu
echo "starting besu node"
NODE_NAME=besu0
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name $NODE_NAME \
  --net host \
  -v "$TESTNET_PATH/public/eth1_config.json:/networkdata/eth1_config.json" \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/besudata" \
  -u $(id -u):$(id -g) \
  -itd $BESU_IMAGE \
  --data-path="/besudata" \
  --genesis-file="/networkdata/eth1_config.json" \
  --rpc-http-enabled --rpc-http-api=ETH,NET,CONSENSUS \
  --rpc-http-host=0.0.0.0 \
  --rpc-http-port=8502 \
  --rpc-http-cors-origins="*" \
  --rpc-ws-enabled --rpc-ws-api=ETH,NET,CONSENSUS \
  --rpc-ws-host=0.0.0.0 \
  --rpc-ws-port=8602 \
  --p2p-port=30302 \
  --Xmerge-support=true \
  --discovery-enabled=false \
  --miner-coinbase="0x1000000000000000000000000000000000000000"

# Run eth2 beacon nodes

# Prysm
echo "starting prysm beacon node"
NODE_NAME=prysm0bn
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/beacondata" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -v "$TESTNET_PATH/public/genesis.ssz:/networkdata/genesis.ssz" \
  -itd $PRYSM_BEACON_IMAGE \
  --accept-terms-of-use=true \
  --datadir="/beacondata" \
  --min-sync-peers=0 \
  --http-web3provider="http://127.0.0.1:8500" \
  --bootstrap-node="$BOOTNODE_ENR" \
  --chain-config-file="/networkdata/eth2_config.yaml" \
  --genesis-state="/networkdata/genesis.ssz" \
  --p2p-host-ip="127.0.0.1" \
  --p2p-max-peers=30 \
  --p2p-udp-port=9000 --p2p-tcp-port=9000 \
  --monitoring-host=0.0.0.0 --monitoring-port=8000 \
  --rpc-host=0.0.0.0 --rpc-port=4100 \
  --grpc-gateway-host=0.0.0.0 \
  --grpc-gateway-port=4000 \
  --verbosity="debug" \
  --enable-debug-rpc-endpoints \
  --min-sync-peers 1 \
  --rpc-max-page-size 500 \
  --slots-per-archive-point=64
# Note: --slots-per-archive-point=64 is to improve local chain explorer performance by storing more state snapshots

# Teku
echo "starting teku beacon node"
NODE_NAME=teku0bn
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/beacondata" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -v "$TESTNET_PATH/public/genesis.ssz:/networkdata/genesis.ssz" \
  -itd $TEKU_DOCKER_IMAGE \
  --network "/networkdata/eth2_config.yaml" \
  --data-path "/beacondata" \
  --p2p-enabled=true \
  --logging=TRACE \
  --initial-state "/networkdata/genesis.ssz" \
  --eth1-endpoint "http://127.0.0.1:8501" \
  --p2p-discovery-bootnodes "$BOOTNODE_ENR" \
  --metrics-enabled=true --metrics-interface=0.0.0.0 --metrics-port=8001 \
  --p2p-discovery-enabled=true \
  --p2p-peer-lower-bound=1 \
  --p2p-port=9001 \
  --rest-api-enabled=true \
  --rest-api-docs-enabled=true \
  --rest-api-interface=0.0.0.0 \
  --rest-api-port=4001 \
  --Xdata-storage-non-canonical-blocks-enabled=true

# Lighthouse
echo "starting lighthouse beacon node"
NODE_NAME=lighthouse0bn
mkdir "$TESTNET_PATH/nodes/$NODE_NAME"
docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/beacondata" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -v "$TESTNET_PATH/public/genesis.ssz:/networkdata/genesis.ssz" \
  -itd $LIGHTHOUSE_DOCKER_IMAGE \
  lighthouse \
  --datadir "/beacondata" \
  --testnet-deposit-contract-deploy-block 0 \
  --testnet-genesis-state "/networkdata/genesis.ssz" \
  --testnet-yaml-config "/networkdata/eth2_config.yaml" \
  --debug-level=trace \
  beacon_node \
  --eth1-endpoints "http://127.0.0.1:8502" \
  --boot-nodes "$BOOTNODE_ENR" \
  --http \
  --http-address 0.0.0.0 \
  --http-port 4002 \
  --metrics \
  --metrics-address 0.0.0.0 \
  --metrics-port 8002 \
  --listen-address 0.0.0.0 \
  --port 9002

if [ $NIMBUS_ENABLED != 0 ]; then
  # Nimbus # TODO: another eth1 node for nimbus to connect to, with websocket RPC exposed (nimbus doesn't support http rpc for eth1 connection)
  echo "starting nimbus beacon node"
  NODE_NAME=nimbus0bn
  mkdir -p "$TESTNET_PATH/nodes/$NODE_NAME/no_bn_keys"
  mkdir -p "$TESTNET_PATH/nodes/$NODE_NAME/no_bn_secrets"
  docker run \
    --name $NODE_NAME \
    --net host \
    -u $(id -u):$(id -g) \
    -v "$TESTNET_PATH/nodes/$NODE_NAME:/beacondata" \
    -v "$TESTNET_PATH/public/nimbus_config.json:/networkdata/nimbus_config.json" \
    -v "$TESTNET_PATH/public/genesis.ssz:/networkdata/genesis.ssz" \
    beacon_node \
    --network="/networkdata/nimbus_config.json" \
    --max-peers="{{hi_peer_count}}" \
    --data-dir="/beacondata" \
    --web3-url="ws://127.0.0.1:8503/ws" \
    --bootstrap-node="$BOOTNODE_ENR" \
    --udp-port=9003 \
    --tcp-port=9003 \
    --listen-address=0.0.0.0 \
    --graffiti="nimbus" \
    --nat="extip:127.0.0.1" \
    --log-level="debug" \
    --log-file="/dev/null" \
    --rpc --rpc-port=4003 --rpc-address=0.0.0.0 \
    --metrics --metrics-port=8003 --metrics-address=0.0.0.0 \
    --validators-dir="/beacondata/no_bn_keys" \
    --secrets-dir="/beacondata/no_bn_secrets"
fi

# validators

# Prysm
echo "starting Prysm validator client"
NODE_NAME=prysm0vc
NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
if [ -d "$NODE_PATH" ]
then
  echo "$NODE_NAME already has existing data"
else
  echo "creating data for $NODE_NAME"
  mkdir -p "$NODE_PATH/wallet/direct/accounts"
  cp "$TESTNET_PATH/private/validator0/prysm/all-accounts.keystore.json" "$NODE_PATH/wallet/direct/accounts/all-accounts.keystore.json"
  cp "$TESTNET_PATH/private/validator0/prysm/keymanageropts.json" "$NODE_PATH/wallet/direct/keymanageropts.json"
  echo -n "$PRYSM_BULK_KEYSTORE_PASS" > "$NODE_PATH/wallet_pass.txt"
fi

docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/validatordata" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -itd $PRYSM_VALIDATOR_IMAGE \
  --accept-terms-of-use=true \
  --datadir="/validatordata" \
  --chain-config-file="/networkdata/eth2_config.yaml" \
  --beacon-rpc-provider=localhost:4100 \
  --graffiti="prysm" \
  --monitoring-host=0.0.0.0 --monitoring-port=8100 \
  --wallet-dir=/validatordata/wallet \
  --wallet-password-file="/validatordata/wallet_pass.txt"


# Teku
echo "starting teku validator client"
NODE_NAME=teku0vc
NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
if [ -d "$NODE_PATH" ]
then
  echo "$NODE_NAME already has existing data"
else
  echo "creating data for $NODE_NAME"
  mkdir -p "$NODE_PATH"
  cp -r "$TESTNET_PATH/private/validator1/teku-keys" "$NODE_PATH/keys"
  cp -r "$TESTNET_PATH/private/validator1/teku-secrets" "$NODE_PATH/secrets"
fi

docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/validatordata" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -v "$TESTNET_PATH/public/genesis.ssz:/networkdata/genesis.ssz" \
  -itd $TEKU_DOCKER_IMAGE \
  validator-client \
  --network "/networkdata/eth2_config.yaml" \
  --data-path "/validatordata" \
  --beacon-node-api-endpoint "http://127.0.0.1:4001" \
  --validators-graffiti="teku" \
  --validator-keys "/validatordata/keys:/validatordata/secrets"


# Lighthouse
echo "starting lighthouse validator client"
NODE_NAME=lighthouse0vc
NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
if [ -d "$NODE_PATH" ]
then
  echo "$NODE_NAME already has existing data"
else
  echo "creating data for $NODE_NAME"
  mkdir -p "$NODE_PATH"
  cp -r "$TESTNET_PATH/private/validator2/keys" "$NODE_PATH/keys"
  cp -r "$TESTNET_PATH/private/validator2/secrets" "$NODE_PATH/secrets"
fi

docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$TESTNET_PATH/nodes/$NODE_NAME:/validatordata" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -v "$TESTNET_PATH/public/genesis.ssz:/networkdata/genesis.ssz" \
  -itd $LIGHTHOUSE_DOCKER_IMAGE \
  lighthouse \
  --testnet-deposit-contract-deploy-block 0 \
  --testnet-genesis-state "/networkdata/genesis.ssz" \
  --testnet-yaml-config "/networkdata/eth2_config.yaml" \
  validator_client \
  --init-slashing-protection \
  --beacon-nodes "http://127.0.0.1:4002" \
  --graffiti="lighthouse" \
  --validators-dir "/validatordata/keys" \
  --secrets-dir "/validatordata/secrets"


# Nimbus
if [ $NIMBUS_ENABLED != 0 ]; then  # TODO enable nimbus
  echo "starting Nimbus validator client"
  NODE_NAME=nimbus0vc
  NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
  if [ -d "$NODE_PATH" ]
  then
    echo "$NODE_NAME already has existing data"
  else
    echo "creating data for $NODE_NAME"
    mkdir -p "$NODE_PATH"
    cp -r "$TESTNET_PATH/private/validator3/nimbus-keys" "$NODE_PATH/keys"
    cp -r "$TESTNET_PATH/private/validator3/secrets" "$NODE_PATH/secrets"
  fi

  docker run \
    --name $NODE_NAME \
    --net host \
    -u $(id -u):$(id -g) \
    -v "$TESTNET_PATH/nodes/$NODE_NAME:/validatordata" \
    -itd $NIMBUS_DOCKER_IMAGE \
    validator_client \
    --log-level="debug" \
    --log-file="/dev/null" \
    --data-dir="/validatordata" \
    --non-interactive=true \
    --graffiti="nimbus" \
    --rpc-port=4003 \
    --rpc-address=127.0.0.1 \
    --validators-dir="/validatordata/keys" \
    --secrets-dir="/validatordata/secrets"
fi

echo "Setting up fork monitor"

# Fork monitor setup
SLOTS_PER_EPOCH=32
SECONDS_PER_SLOT=12
ETH2_MIN_GENESIS_ACTIVE_VALIDATOR_COUNT=16384
if [ "$ETH2_SPEC_VARIANT" == "minimal" ]; then
  SLOTS_PER_EPOCH=8
  SECONDS_PER_SLOT=6
  ETH2_MIN_GENESIS_ACTIVE_VALIDATOR_COUNT=64
fi

NODE_NAME=forkmon0
NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
mkdir -p "$NODE_PATH"
cat > "$NODE_PATH/config.yaml"  << EOT
# disabled
weak_subjectivity_provider_endpoint: ""
# disabled
etherscan_api_key: ""
http_timeout_milliseconds: 2000
endpoints:
  # Prysm
  - addr: http://127.0.0.1:4000
    eth1: Geth
  # Teku
  - addr: http://127.0.0.1:4001
    eth1: Besu
  # Lighthouse
  - addr: http://127.0.0.1:4002
    eth1: Nethermind
# Dir for web assets
outputDir: /public
eth2:
  seconds_per_slot: ${SECONDS_PER_SLOT}
  genesis_time: ${ETH2_GENESIS_TIMESTAMP}
  slots_per_epoch: ${SLOTS_PER_EPOCH}
  network: Local
EOT

docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$NODE_PATH:/data" \
  -itd $FORKMON_IMAGE \
  -config-file=/data/config.yaml

echo "fork monitor running at: http://127.0.0.1:8080/"


echo "Setting up postgres database for explorer"
NODE_NAME=postgres0
NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
mkdir -p "$NODE_PATH"
# Run the database in the background
docker run \
  --name $NODE_NAME \
  --net host \
  -e POSTGRES_PASSWORD=pass \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=db \
  -e PGDATA=/postgresql/data \
  -u $(id -u):$(id -g) \
  -v "$NODE_PATH:/postgresql/data" \
  -itd $POSTGRES_IMAGE

# Wait for postgres docker container to get online
sleep 5

echo "Initializing the postgres tables..."
docker run -it --rm \
  --net=host \
  -u $(id -u):$(id -g) \
  -v "$EXPLORER_TABLES_SQL_PATH:/src/tables.sql" \
  -it $POSTGRES_IMAGE \
  psql -f /src/tables.sql -d db -h 0.0.0.0 -p 5432 -U postgres


echo "Setting up explorer"

NODE_NAME=explorer0
NODE_PATH="$TESTNET_PATH/nodes/$NODE_NAME"
mkdir -p "$NODE_PATH"
cat > "$NODE_PATH/imprint.html" << EOT
{{ define "js"}}
{{end}}

{{ define "css"}}
{{end}}

{{ define "content"}}
    {{with .Data}}
        <div class="container mt-2">
            <h2>Local merge testnet explorer! Fork of <a href="https://github.com/gobitfly/eth2-beaconchain-explorer">Eth2 beaconcha.in explorer</a>.</h2>
        </div><a href="/" class="btn btn-primary mt-4">Back</a>
        </div>
    {{end}}
{{end}}
EOT

cat > "$NODE_PATH/config.yaml"  << EOT
# Database credentials
database:
  user: "postgres"
  name: "db"
  host: "127.0.0.1"
  port: "5432"
  password: "pass"

# Chain network configuration
chain:
  slotsPerEpoch: ${SLOTS_PER_EPOCH}
  secondsPerSlot: ${SECONDS_PER_SLOT}
  minGenesisActiveValidatorCount: ${ETH2_MIN_GENESIS_ACTIVE_VALIDATOR_COUNT}
  genesisTimestamp: ${ETH2_GENESIS_TIMESTAMP}
  mainnet: false  # hide mainnet staking pool etc. info
  phase0path: "/networkdata/eth2_config.yaml"

# Note: It is possible to run either the frontend or the indexer or both at the same time
# Frontend config
frontend:
  enabled: true # Enable or disable to web frontend
  imprint: "/imprint.html"  # Path to the imprint page content
  siteName: "Ethereum Merge Local Devnet Explorer" # Name of the site, displayed in the title tag
  siteSubtitle: "Merge explorer" # Subtitle shown on the main page
  csrfAuthKey: '0123456789abcdef000000000000000000000000000000000000000000000000'
  jwtSigningSecret: "0123456789abcdef000000000000000000000000000000000000000000000000"
  jwtIssuer: "localblockexplorer"
  jwtValidityInMinutes: 30
  server:
    host: "localhost" # Address to listen on
    port: "9333" # Port to listen on
  database:
    user: "postgres"
    name: "db"
    host: "127.0.0.1"
    port: "5432"
    password: "pass"
  # sessionSecret: "<sessionSecret>"
  # flashSecret: "" # Encryption secret for flash cookies

# Indexer config
indexer:
  enabled: true # Enable or disable the indexing service
  fullIndexOnStartup: false # Perform a one time full db index on startup
  indexMissingEpochsOnStartup: true # Check for missing epochs and export them after startup
  node:
    host: "localhost" # Address of the backend node
    port: "4100" # GRPC port of the Prysm node
    type: "prysm" # can be either prysm or lighthouse
    pageSize: 500 # the amount of entries to fetch per paged rpc call
  eth1Endpoint: 'http://127.0.0.1:8500'
  eth1DepositContractAddress: '0x4242424242424242424242424242424242424242'
  # Note: 0 is correct, but due to an underflow bug (being fixed), doesn't work.
  eth1DepositContractFirstBlock: 1
EOT

docker run \
  --name $NODE_NAME \
  --net host \
  -u $(id -u):$(id -g) \
  -v "$NODE_PATH/config.yaml:/config.yaml" \
  -v "$NODE_PATH/imprint.html:/imprint.html" \
  -v "$TESTNET_PATH/public/eth2_config.yaml:/networkdata/eth2_config.yaml" \
  -itd $EXPLORER_IMAGE \
  ./explorer --config /config.yaml
