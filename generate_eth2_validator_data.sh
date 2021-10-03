#!/bin/bash

ETH2_BASE_CONFIG="mainnet"
if grep -q "eth2_base_config: minimal" mergenet.yaml; then
    ETH2_BASE_CONFIG="minimal"
fi

# Inside your setupenv: Generate Genesis Beacon State
if [ "$ETH2_BASE_CONFIG" = "minimal" ]; then
    echo "[*] Using minimal config"
    eth2-testnet-genesis merge \
                         --preset-phase0 minimal --preset-altair minimal --preset-merge minimal \
                         --eth1-config "$TESTNET_NAME/public/eth1_config.json" \
                         --config "$TESTNET_NAME/public/eth2_config.yaml" \
                         --mnemonics genesis_validators.yaml \
                         --state-output "$TESTNET_NAME/public/genesis.ssz" \
                         --tranches-dir "$TESTNET_NAME/private/tranches"
else
    echo "[*] Using mainnet config"
    eth2-testnet-genesis merge \
                         --eth1-config "$TESTNET_NAME/public/eth1_config.json" \
                         --config "$TESTNET_NAME/public/eth2_config.yaml" \
                         --mnemonics genesis_validators.yaml \
                         --state-output "$TESTNET_NAME/public/genesis.ssz" \
                         --tranches-dir "$TESTNET_NAME/private/tranches"
fi


# Build validator keystore for nodes
#
# Prysm likes to consume bundled keystores. Use `--prysm-pass` to encrypt the bundled version.
# For the other eth2 clients, a different secret is generated per validator keystore.
#
# You can change the range of validator accounts, to split keys between nodes.
# The mnemonic and key-range should match that of a tranche of validators in the beacon-state genesis.
echo "[*] Building validator keystores"
eth2-val-tools keystores \
  --out-loc "$TESTNET_NAME/private/$VALIDATOR_NODE_NAME" \
  --prysm-pass="foobar" \
  --source-min=0 \
  --source-max=64 \
  --source-mnemonic="lumber kind orange gold firm achieve tree robust peasant april very word ordinary before treat way ivory jazz cereal debate juice evil flame sadness"
