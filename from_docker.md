# TODO

Docker images:

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

### Geth

[Docs](https://geth.ethereum.org/docs/install-and-build/installing-geth#run-inside-docker-container)
```
ethereum/client-go:latest
```

### Nethermind

[Docs](https://docs.nethermind.io/nethermind/ethereum-client/docker)
```
nethermind/nethermind:latest
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

### Lighthouse

Note: The image entry point is plain shell. And the Beacon node (`bn`) and Validator client (`vc`) are available through the same binary. Use looks like `docker run sigp/lighthouse:rayonism lighthouse bn --options-here`

[Docs](https://lighthouse-book.sigmaprime.io/docker.html)

Note: 
```
sigp/lighthouse:rayonism
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

