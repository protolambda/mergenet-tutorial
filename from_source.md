# Building clients from source

When making changes to clients for interop purposes, you may not want to use docker.
This doc describes how to build every client from source.

This guide assumes a Linux or MacOS install.
For Windows, please refer to the build instructions by the client (if compatible with windows at all).


## Geth

### Prerequisites

1. Install `go`
2. Add Go to your Path:
```shell
export GOPATH=$HOME/go
export GOROOT=/usr/lib/go
export PATH="$PATH:$GOPATH/bin"
```

### Build

```shell
git clone git@github.com:ethereum/go-ethereum.git
cd go-ethereum

# To build a binary:
go build -o ./build/bin/catalyst ./cmd/geth
# Or, to build a binary and add it to your go bin path:
go install ./cmd/geth
```

----

## Nethermind

### Prerequisites

1. Install `dotnet-sdk` and `dotnet-runtime`
2. Add Dotnet to your Path:
```shell
export PATH="$PATH:$HOME/.dotnet/tools"
```
3. Check if you have the aspnet runtime: `dotnet --list-runtimes`
4. Install `aspnet-runtime` if you have not
5. `libsnappy-dev libc6-dev libc6` (snappy and glibc)

### Build

```shell
git clone git@github.com:NethermindEth/nethermind.git
cd nethermind
# Make sure you have git-submoduled dependencies
git submodule init
git submodule update

cd src/Nethermind
dotnet build Nethermind.sln -c Release
```

### Run

```shell
cd src/Nethermind/Nethermind.Runner
dotnet run -c Release --no-build -- --options-here
```

----

## Teku (TXRX fork)

### Prerequisites

1. Install open-jdk 15+ (or oracle jdk)

### Build

```shell
git clone https://github.com/txrx-research/teku.git
cd teku

./gradlew installDist
```

### Run

```shell
./build/install/teku/bin/teku --options-here
```

----

## Prysm

### Prerequisites

1. Install go 1.16+
2. Install Bazel 3.7 (warning, older than latest bazel 4). Use bazelisk to install bazel.
   - See https://github.com/bazelbuild/bazelisk/blob/master/README.md
   - Alias bazelisk to bazel
3. Work around LLVM build issue (warning: no success here so far). https://github.com/prysmaticlabs/prysm/issues/8072
4. If you want to build docker images, patch bazel workspace with https://github.com/bazelbuild/rules_docker/releases/tag/v0.17.0
   See https://github.com/bazelbuild/rules_docker/issues/1814 for context.

### Build

```shell
git clone -b merge git@github.com:prysmaticlabs/prysm.git
cd prysm
```

```shell
bazel build //beacon-chain:beacon-chain
bazel build //validator:validator
```

To generate docker images:

```shell
# Note: suffix '--define=ssz=minimal' to the bazel commands to build for minimal variant of eth2 spec 
bazel run //beacon-chain:image_bundle
bazel run //validator:image_bundle

# retag the images to rayonism specific names
docker tag gcr.io/prysmaticlabs/prysm/beacon-chain:latest protolambda/prysm-beacon:rayonism-minimal
docker tag gcr.io/prysmaticlabs/prysm/validator:latest protolambda/prysm-validator:rayonism-minimal
```

### Run

TODO

----

## Lighthouse

### Prerequisites

1. Install Rust. Recommendation: install "rustup", to easily switch rust versions.
   ```shell
   # System deps (assuming Ubuntu, you may need to parse to your OS)
   sudo apt install -y git gcc g++ make cmake pkg-config
   # Install Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```
2. Select stable rust version: `rustup +stable default`
3. Update your rust version (if installed previously): `rustup +stable update`

### Build

Checkout lighthouse rayonism, then run the make script:
```shell
git clone -b rayonism git@github.com:sigp/lighthouse.git
cd lighthouse

make install
```

### Run

```shell
./target/release/lighthouse --options-here
```
