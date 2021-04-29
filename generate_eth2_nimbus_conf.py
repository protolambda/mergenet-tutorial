import ruamel.yaml as yaml
import sys
import json

mergenet_config_path = "mergenet.yaml"
if len(sys.argv) > 1:
    mergenet_config_path = sys.argv[1]

with open(mergenet_config_path) as stream:
    data = yaml.safe_load(stream)

mainnet = {
    'CONFIG_NAME': 'mainnet',
    'MAX_COMMITTEES_PER_SLOT': 64,
    'TARGET_COMMITTEE_SIZE': 128,
    'SHUFFLE_ROUND_COUNT': 90,
    'MIN_GENESIS_ACTIVE_VALIDATOR_COUNT': 16384,
    'ETH1_FOLLOW_DISTANCE': 2048,
    'SECONDS_PER_SLOT': 12,
    'SLOTS_PER_EPOCH': 32,
    'EPOCHS_PER_ETH1_VOTING_PERIOD': 64,
    'SLOTS_PER_HISTORICAL_ROOT': 8192,
    'SHARD_COMMITTEE_PERIOD': 256,
    'EPOCHS_PER_HISTORICAL_VECTOR': 65536,
    'EPOCHS_PER_SLASHINGS_VECTOR': 8192,
    'INACTIVITY_PENALTY_QUOTIENT': 67108864,
    'MIN_SLASHING_PENALTY_QUOTIENT': 128,
    'PROPORTIONAL_SLASHING_MULTIPLIER': 1,
}

minimal = {
    'CONFIG_NAME': 'minimal',
    'MAX_COMMITTEES_PER_SLOT': 4,
    'TARGET_COMMITTEE_SIZE': 4,
    'SHUFFLE_ROUND_COUNT': 10,
    'MIN_GENESIS_ACTIVE_VALIDATOR_COUNT': 64,
    'ETH1_FOLLOW_DISTANCE': 16,
    'SECONDS_PER_SLOT': 6,  # TODO: maybe just keep this 12?
    'SLOTS_PER_EPOCH': 8,
    'EPOCHS_PER_ETH1_VOTING_PERIOD': 4,
    'SLOTS_PER_HISTORICAL_ROOT': 64,
    'SHARD_COMMITTEE_PERIOD': 64,
    'EPOCHS_PER_HISTORICAL_VECTOR': 64,
    'EPOCHS_PER_SLASHINGS_VECTOR': 64,
    'INACTIVITY_PENALTY_QUOTIENT': 33554432,
    'MIN_SLASHING_PENALTY_QUOTIENT': 64,
    'PROPORTIONAL_SLASHING_MULTIPLIER': 2,
}

config = minimal if data['eth2_base_config'] == 'minimal' else mainnet

# attempt to get nimbus custom local config working.
print(json.dumps({
    "runtimePreset": {
        "MIN_GENESIS_ACTIVE_VALIDATOR_COUNT": config['MIN_GENESIS_ACTIVE_VALIDATOR_COUNT'],
        "MIN_GENESIS_TIME": 1606824000,
        "GENESIS_DELAY": int(data['eth2_genesis_delay']),
        "GENESIS_FORK_VERSION": f"{data['eth2_fork_version']}",
        "ETH1_FOLLOW_DISTANCE": config['ETH1_FOLLOW_DISTANCE'],
        "DEPOSIT_CHAIN_ID": data['chain_id'],
        "DEPOSIT_NETWORK_ID": data['chain_id'],
    },
    "depositContractAddress": data['deposit_contract_address'],
    "depositContractDeployedAt": "0x" + "00" * 32,  # TODO: need to specify eth1 genesis block hash
}, indent="  "))
