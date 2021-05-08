# Running nodes with Docker

This doc guides you through running each client
with custom testnet configuration for testing the Rayonism merge prototypes.

All of the instructions are very verbose about port configuration,
so you can change the ports easily, and avoid port overlaps. 

Each of the instructions assumes you want to mount 
testnet configuration, a datadir for the node, maybe a genesis-state for beacon nodes, and maybe keys/secrets for validators.

It's recommended you create the data dirs on the host, so docker doesn't have to during the run, and permissions match the user-permissions in the container.
Nethermind is an odd one here, running as non-root user is problematic.

## Tooling

[Docs](https://github.com/protolambda/eth2-bootnode)

```
protolambda/eth2-bootnode:latest
```

## Execution clients

### Besu

[Docs](https://besu.hyperledger.org/en/stable/HowTo/Get-Started/Installation-Options/Run-Docker-Image/)

Note: merge/rayonism is not supported on the main branch/images yet. Use below image, from one of the Besu devs:
```
suburbandad/besu:rayonism
```

#### Running

```shell
docker run \
  --name besu0 \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/public/eth1_config.json:/networkdata/eth1_config.json \
  -v ${PWD}/$TESTNET_NAME/nodes/besu0:/besudata \
  suburbandad/besu:rayonism \
  --data-path="/besudata" \
  --genesis-file="/networkdata/eth1_config.json" \
  --rpc-http-enabled --rpc-http-api=ETH,NET,CONSENSUS \
  --rpc-http-host=0.0.0.0 \
  --rpc-http-port=8545 \
  --rpc-http-cors-origins="*" \
  --rpc-ws-enabled --rpc-ws-api=ETH,NET,CONSENSUS \
  --rpc-ws-host=0.0.0.0 \
  --rpc-ws-port=8546 \
  --Xmerge-support=true \
  --discovery-enabled=false \
  --miner-coinbase="0x1000000000000000000000000000000000000000"
```

### Geth

[Docs](https://geth.ethereum.org/docs/install-and-build/installing-geth#run-inside-docker-container)
```
ethereum/client-go:latest
```

#### Initialization

Important: for custom testnets, you will need to init the data-dir before running the client, like below:

```shell
docker run \
  --name tmpgeth \
  --rm \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/public/eth1_config.json:/networkdata/eth1_config.json \
  -v ${PWD}/$TESTNET_NAME/nodes/geth0:/gethdata \
  ethereum/client-go:latest
  --catalyst \
  --datadir "/gethdata/chaindata" \
  init "/networkdata/eth1_config.json"
```

#### Running:

```shell
docker run \
  --name geth0 \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/public/eth1_config.json:/networkdata/eth1_config.json \
  -v ${PWD}/$TESTNET_NAME/nodes/geth0:/gethdata \
  ethereum/client-go:latest
  --catalyst
  --http --http.api net,eth,consensus
  --http.port 8545
  --http.addr 0.0.0.0
  --http.corsdomain "*"
  --ws --ws.api net,eth,consensus
  --ws.port 8546
  --ws.addr 0.0.0.0
  --nodiscover
  --miner.etherbase 0x1000000000000000000000000000000000000000
  --datadir "/gethdata/chaindata"
```

### Nethermind

[Docs](https://docs.nethermind.io/nethermind/ethereum-client/docker)
```
nethermind/nethermind:latest
```

#### Running:

Note: the nethermind docker cannot handle user changes (error on p2p key write, permissions problem), the container runs nethermind root internally.
```shell
docker run \
  --name nethermind0 \
  -v ${PWD}/$TESTNET_NAME/public/eth1_nethermind_config.json:/networkdata/eth1_nethermind_config.json \
  -v ${PWD}/$TESTNET_NAME/nodes/nethermind0:/netherminddata \
  -itd nethermind/nethermind \
  --datadir "/netherminddata" \
  --Init.ChainSpecPath "/networkdata/eth1_nethermind_config.json" \
  --Init.WebSocketsEnabled true \
  --JsonRpc.Port 8545 \
  --JsonRpc.WebSocketsPort 8546 \
  --JsonRpc.Host 0.0.0.0 \
  --Merge.BlockAuthorAccount 0x1000000000000000000000000000000000000000
```

## Consensus clients

### Teku

Note starts a beacon node by default, use the `validator` subcommand to run the separate validator-client.

[Docs](https://docs.teku.consensys.net/en/latest/HowTo/Get-Started/Installation-Options/Run-Docker-Image/)

Note: the main repo does not support merge/rayonism yet.
Use the below image by Mikhail, working on the TXRX (a Consensys R&D team) fork: 
```
mkalinin/teku:rayonism
```

#### Running the beacon node:

```shell
docker run \
  --name teku0bn \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/teku0bn:/beacondata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  -v ${PWD}/$TESTNET_NAME/public/genesis.ssz:/networkdata/genesis.ssz \
  mkalinin/teku:rayonism \
  --network "/networkdata/eth2_config.yaml" \
  --data-path "/beacondata" \
  --p2p-enabled=true \
  --logging=debug \
  --initial-state "/networkdata/genesis.ssz" \
  --eth1-endpoint "http://localhost:8545" \
  --p2p-discovery-bootnodes "COMMA_SEPARATED_ENRS_HERE" \
  --metrics-enabled=true --metrics-interface=0.0.0.0 --metrics-port="8000" \
  --p2p-discovery-enabled=true \
  --p2p-peer-lower-bound=1 \
  --p2p-port="9000" \
  --rest-api-enabled=true \
  --rest-api-docs-enabled=true \
  --rest-api-interface=0.0.0.0 \
  --rest-api-port="4000" \
  --metrics-host-allowlist="*" \
  --rest-api-host-allowlist="*" \
  --Xdata-storage-non-canonical-blocks-enabled=true
  # optional:
  # --p2p-advertised-ip=1.2.3.4
```

#### Running the validator:

```shell
# prepare keys
NODE_PATH="$TESTNET_PATH/nodes/teku0vc"
mkdir -p "$NODE_PATH"
cp -r "$TESTNET_PATH/private/validator0/teku-keys" "$NODE_PATH/keys"
cp -r "$TESTNET_PATH/private/validator0/teku-secrets" "$NODE_PATH/secrets"

docker run \
  --name teku0vc \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/teku0vc:/validatordata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  mkalinin/teku:rayonism \
  --network "/networkdata/eth2_config.yaml" \
  --data-path "/validatordata" \
  --beacon-node-api-endpoint "http://localhost:4000" \
  --validators-graffiti="hello" \
  --validator-keys "/validatordata/keys:/validatordata/secrets"
```

### Lighthouse

Note: The image entry point is plain shell. And the Beacon node (`bn`) and Validator client (`vc`) are available through the same binary. Use looks like `docker run sigp/lighthouse:rayonism lighthouse bn --options-here`

[Docs](https://lighthouse-book.sigmaprime.io/docker.html)

Note: merge prototype work is not part of the client yet, use the `rayonism` docker tag instead.
```
sigp/lighthouse:rayonism
```

#### Running the beacon node:

```shell
docker run \
  --name lighthouse0bn \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/lighthouse0bn:/beacondata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  -v ${PWD}/$TESTNET_NAME/public/genesis.ssz:/networkdata/genesis.ssz \
  sigp/lighthouse:rayonism \
  lighthouse \
  --datadir "/beacondata" \
  --testnet-deposit-contract-deploy-block 0 \
  --testnet-genesis-state "/networkdata/genesis.ssz" \
  --testnet-yaml-config "/networkdata/eth2_config.yaml" \
  --debug-level=debug \
  beacon_node \
  --enr-tcp-port=9000 --enr-udp-port=9000 \
  --port=9000 --discovery-port=9000 \
  --eth1-endpoints "http://localhost:8545" \
  --boot-nodes "COMMA_SEPARATED_ENRS_HERE" \
  --http \
  --http-address 0.0.0.0 \
  --http-port "4000" \
  --metrics \
  --metrics-address 0.0.0.0 \
  --metrics-port "8000" \
  --listen-address 0.0.0.0
  # optional:
  # --enr-address=1.2.3.4
```

#### Running the validator:

```shell
# prepare keys
NODE_PATH="$TESTNET_PATH/nodes/lighthouse0vc"
mkdir -p "$NODE_PATH"
cp -r "$TESTNET_PATH/private/validator0/keys" "$NODE_PATH/keys"
cp -r "$TESTNET_PATH/private/validator0/secrets" "$NODE_PATH/secrets"

docker run \
  --name lighthouse0vc \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/lighthouse0vc:/validatordata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  sigp/lighthouse:rayonism \
  lighthouse \
  --testnet-deposit-contract-deploy-block 0 \
  --testnet-genesis-state "/networkdata/genesis.ssz" \
  --testnet-yaml-config "/networkdata/eth2_config.yaml" \
  validator_client \
  --init-slashing-protection \
  --beacon-nodes "http://localhost:4000" \
  --graffiti="hello" \
  --validators-dir "/validatordata/keys" \
  --secrets-dir "/validatordata/secrets"
```


### Prysm

Note: `mainnet` and `minimal` refer to base configurations. Custom testnet configs can extend one of these two.

[Docs](https://docs.prylabs.network/docs/install/install-with-docker)

```
gcr.io/prysmaticlabs/prysm/beacon-chain:merge-mainnet
gcr.io/prysmaticlabs/prysm/validator:merge-mainnet

gcr.io/prysmaticlabs/prysm/beacon-chain:merge-minimal
gcr.io/prysmaticlabs/prysm/validator:merge-minimal
```

#### Running the beacon node:

```shell
docker run \
  --name prysm0bn \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/prysm0bn:/beacondata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  -v ${PWD}/$TESTNET_NAME/public/genesis.ssz:/networkdata/genesis.ssz \
  gcr.io/prysmaticlabs/prysm/beacon-chain:merge-minimal \
  --accept-terms-of-use=true \
  --datadir="/beacondata" \
  --min-sync-peers=0 \
  --http-web3provider="http://localhost:8545" \
  --bootstrap-node="REPEAT_THIS_FLAG_TO_ADD_EVERY_ENR" \
  --chain-config-file="/networkdata/eth2_config.yaml" \
  --genesis-state="/networkdata/genesis.ssz" \
  --verbosity=debug \
  --p2p-max-peers=30 \
  --p2p-udp-port=9000 --p2p-tcp-port=9000 \
  --monitoring-host=0.0.0.0 --monitoring-port=8000 \
  --rpc-host=0.0.0.0 --rpc-port=4001 \
  --grpc-gateway-host=0.0.0.0 \
  --grpc-gateway-port=4000 \
  --verbosity="debug" \
  --enable-debug-rpc-endpoints \
  --min-sync-peers 1
  # Optional:
  # --p2p-host-ip=1.2.3.4
```

#### Running the validator:

```shell
# prepare keys
NODE_PATH="$TESTNET_PATH/nodes/prysm0vc"
mkdir -p "$NODE_PATH/wallet/direct/accounts"
cp "$TESTNET_PATH/private/validator0/prysm/all-accounts.keystore.json" "$NODE_PATH/wallet/direct/accounts/all-accounts.keystore.json"
cp "$TESTNET_PATH/private/validator0/prysm/keymanageropts.json" "$NODE_PATH/wallet/direct/keymanageropts.json"
echo -n "bulkpasshere" > "$NODE_PATH/wallet_pass.txt"

docker run \
  --name prysm0vc \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/prysm0vc:/validatordata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  gcr.io/prysmaticlabs/prysm/validator:merge-minimal \
  --accept-terms-of-use=true \
  --datadir="/validatordata" \
  --chain-config-file="/networkdata/eth2_config.yaml" \
  --beacon-rpc-provider="127.0.0.1:4001" \
  --graffiti="hello" \
  --wallet-dir=/validatordata/wallet \
  --wallet-password-file="/validatordata/pass.txt"
```

### Nimbus

Note: different docker images for different configs. Loading custom testnet configurations is still a W.I.P.

[Docs](https://nimbus.guide/docker.html)

Nimbus has an official docker repo, but no rayonism image or docker support for separate validator client (as far Proto knows).
```
statusteam/nimbus_beacon_node
```

You can try these images by proto instead, containing `beacon_node` and `validator_client` binaries:
```
protolambda/nimbus:rayonism
protolambda/nimbus:rayonism-minimal
```
Or compile them yourself with https://github.com/protolambda/nimbus-docker/ (note: you need to add `-d:disableMarchNative` to NIMFLAGS to make your docker image portable)

#### Running the beacon node:

```shell
docker run \
  --name nimbus0bn \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/nimbus0bn:/beacondata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  -v ${PWD}/$TESTNET_NAME/public/genesis.ssz:/networkdata/genesis.ssz \
  protolambda/nimbus:rayonism-minimal \
  beacon_node \
  --network=TODO \
  --max-peers="60" \
  --data-dir="/beacondata" \
  --web3-url="ws://localhost:8546" \
  --bootstrap-node="REPEAT_THIS_FLAG_TO_ADD_EVERY_ENR" \
  --udp-port=9000 \
  --tcp-port=9000 \
  --listen-address=0.0.0.0 \
  --graffiti="hello" \
  --enr-auto-update=false \
  --log-level="debug" \
  --log-file="/dev/null" \
  --rpc --rpc-port=4001 --rpc-address=0.0.0.0 \
  --rest --rest-port=4000 --rpc-address=0.0.0.0 \
  --metrics --metrics-port=8000 --metrics-address=0.0.0.0 \
  --log-file="/dev/null"
# optional:
# --nat="extip:1.2.3.4"
```

Note: local network configuration is undocumented and does not work out of the box.
May require custom docker image.

Note: websocket eth1 connections only.
- `ws://127.0.0.1:8546` for geth
- `ws://127.0.0.1:8546/ws` for besu
- `http://127.0.0.1:8546` (upgrades to websocket) for nethermind

#### Running the validator:

Note: nimbus validators fetch the spec config from the beacon node

```shell
# prepare keys
NODE_PATH="$TESTNET_PATH/nodes/nimbus0vc"
mkdir -p "$NODE_PATH"
cp -r "$TESTNET_PATH/private/validator0/nimbus-keys" "$NODE_PATH/keys"
cp -r "$TESTNET_PATH/private/validator0/secrets" "$NODE_PATH/secrets"

docker run \
  --name nimbus0vc \
  -u $(id -u):$(id -g) --net host \
  -v ${PWD}/$TESTNET_NAME/nodes/nimbus0vc:/validatordata \
  -v ${PWD}/$TESTNET_NAME/public/eth2_config.yaml:/networkdata/eth2_config.yaml \
  protolambda/nimbus:rayonism-minimal \
  validator_client \
  --log-level="debug" \
  --log-file="/dev/null" \
  --data-dir="/validatordata" \
  --non-interactive=true \
  --graffiti="hello" \
  --rpc-port=4001 \
  --rpc-address=127.0.0.1 \
  --validators-dir="/validatordata/keys" \
  --secrets-dir="/validatordata/secrets"
```

Note: Nimbus exposes both a JSON-RPC and REST-API endpoint.
The validator client still uses JSON-RPC, although the standard is REST-API.
