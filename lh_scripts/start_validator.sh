if [ -z "$TESTNET_NAME" ]; then
    echo TESTNET_NAME is not set, exiting
    exit 1
fi
if [ -z "$VALIDATOR_NODE_NAME" ]; then
    echo VALIDATOR_NODE_NAME is not set, exiting
    exit 1
fi

lighthouse \
    --datadir "$TESTNET_NAME/nodes/lighthouse" \
    --testnet-deposit-contract-deploy-block 0 \
    --testnet-genesis-state "$TESTNET_NAME/public/genesis.ssz" \
    --testnet-yaml-config "$TESTNET_NAME/public/eth2_config.yaml" \
    validator_client \
    --init-slashing-protection \
    --validators-dir "./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/keys" \
    --secrets-dir "./$TESTNET_NAME/private/$VALIDATOR_NODE_NAME/secrets" \
