BINARY=binary
DOCKER=docker
DOCKER_IMAGE=sigp/lighthouse:rayonism

if [ -z "$TESTNET_NAME" ]; then
    echo TESTNET_NAME is not set, exiting
    exit 1
fi
if [ -z "$1" ]; then
    echo The first argument must be \"$BINARY\" or \"$DOCKER\", exiting
    exit 1
fi

COMMON_LH_PARAMS="--testnet-deposit-contract-deploy-block 0 \
    --testnet-genesis-state "$TESTNET_NAME/public/genesis.ssz" \
    --testnet-yaml-config "$TESTNET_NAME/public/eth2_config.yaml" \
    validator_client \
    --init-slashing-protection \
    --validators-dir "./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/keys" \
    --secrets-dir "./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/secrets""

if [ $1 = $BINARY ]; then
    exec lighthouse \
        --datadir "$(pwd)/$TESTNET_NAME/nodes/lighthouse_binary" \
        $COMMON_LH_PARAMS
    exit 0
fi

if [ $1 = $DOCKER ]; then
    docker pull $DOCKER_IMAGE &&
    exec docker \
        run \
        --net host \
        --mount 'type=bind,source='$(pwd)'/'$TESTNET_NAME',target=/'$TESTNET_NAME \
        $DOCKER_IMAGE \
        lighthouse \
        $COMMON_LH_PARAMS
    exit 0
fi

echo "Unknown argument: $1. Use \"$BINARY\" or \"$DOCKER\"."
