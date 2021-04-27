LIGHTHOUSE_DOCKER_IMAGE=sigp/lighthouse:rayonism
TEKU_DOCKER_IMAGE=mkalinin/teku:rayonism
NETHERMIND_IMAGE=nethermind/nethermind:latest
GETH_IMAGE=ethereum/client-go:latest

# Ensure necessary env vars are present.
if [ -z "$TESTNET_NAME" ]; then
    echo TESTNET_NAME is not set, exiting
    exit 1
fi

mkdir -p "testnets/$TESTNET_NAME"
TESTNET_PATH="${PWD}/testnets/$TESTNET_NAME"

# Pull client images
docker pull $LIGHTHOUSE_DOCKER_IMAGE
docker pull $TEKU_DOCKER_IMAGE
docker pull $NETHERMIND_IMAGE
docker pull $GETH_IMAGE

# Create venv for scripts
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt


# Prepare keystores
# TODO
eth2-val-tools keystores \
  --out-loc "$TESTNET_PATH/private/$VALIDATOR_NODE_NAME" \
  --prysm-pass="foobar" \
  --source-min=0 \
  --source-max=64 \
  --source-mnemonic="lumber kind orange gold firm achieve tree robust peasant april very word ordinary before treat way ivory jazz cereal debate juice evil flame sadness"

# Configure testnet
mkdir "$TESTNET_PATH/public"
mkdir "$TESTNET_PATH/private"
mkdir "$TESTNET_PATH/nodes"

# Configure Eth1 chain
python generate_eth1_conf.py > "$TESTNET_PATH/public/eth1_config.json"
# Configure Eth1 chain for Nethermind
python generate_eth1_nethermind_conf.py > "$TESTNET_PATH/public/eth1_nethermind_config.json"
# Configure Eth2 chain
python generate_eth2_conf.py > "$TESTNET_PATH/public/eth2_config.yaml"

# Generate Genesis Beacon State
eth2-testnet-genesis merge \
  --eth1-config "$TESTNET_PATH/public/eth1_config.json" \
  --eth2-config "$TESTNET_PATH/public/eth2_config.yaml" \
  --mnemonics genesis_validators.yaml \
  --state-output "$TESTNET_PATH/public/genesis.ssz" \
  --tranches-dir "$TESTNET_PATH/private/tranches"


# prepare eth1 chaindata
docker run \
  --name geth \
  -v "$TESTNET_PATH/nodes/geth0:/gethdata" \
  --net host \
  -itd $GETH_IMAGE \
  --catalyst \
  --datadir "/gethdata/chaindata" \
  init "./$TESTNET_PATH/public/eth1_config.json"

# Run eth1 nodes

# Go-ethereum
docker run \
  --name geth \
  -v "$TESTNET_PATH/nodes/geth0:/gethdata" \
  --net host \
  -itd $GETH_IMAGE \
  --catalyst \
  --http --http.api net,eth,consensus \
  --http.port 8545 \
  --http.addr 0.0.0.0 \
  --nodiscover \
  --miner.etherbase 0x1000000000000000000000000000000000000000 \
  --datadir "/gethdata/chaindata"

# Nethermind
docker run \
  --name nethermind \
  --net host \
  -v "$TESTNET_PATH/public/eth1_nethermind_config.json:/nethermind/chainspec/catalyst.json" \
  -v "$TESTNET_PATH/nodes/nethermind0/db:/nethermind/nethermind_db" \
  -v "$TESTNET_PATH/nodes/nethermind0/logs:/nethermind/logs" \
  -itd $NETHERMIND_IMAGE \
  -c catalyst \
  --JsonRpc.Port 8545 \
  --JsonRpc.Host 0.0.0.0 \
  --Merge.BlockAuthorAccount 0x1000000000000000000000000000000000000000

# Run eth2 nodes

# Teku
# TODO

# Lighthouse
# TODO

# Prysm
# TODO

# Nimbus
# TODO


COMMON_LH_PARAMS="--testnet-deposit-contract-deploy-block 0 \
    --testnet-genesis-state "$TESTNET_NAME/public/genesis.ssz" \
    --testnet-yaml-config "$TESTNET_NAME/public/eth2_config.yaml" \
    beacon_node \
    --staking"

# Start Lighthouse using the binary available on $PATH.
if [ $1 = $BINARY ]; then
    exec lighthouse \
        --datadir "$(pwd)/$TESTNET_NAME/nodes/lighthouse_binary" \
        $COMMON_LH_PARAMS
    exit 0
fi

# Start Lighthouse using a docker image on Docker Hub.
if [ $1 = $DOCKER ]; then
    docker pull $DOCKER_IMAGE &&
    exec docker \
        run \
        --net host \
        --mount 'type=bind,source='$(pwd)'/testnets/'$TESTNET_NAME',target=/'$TESTNET_NAME \
        $DOCKER_IMAGE \
        lighthouse \
        --datadir "/$TESTNET_NAME/nodes/lighthouse_docker" \
        $COMMON_LH_PARAMS
    exit 0
fi

echo "Unknown argument: $1. Use \"$BINARY\" or \"$DOCKER\"."
