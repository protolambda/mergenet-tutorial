import ruamel.yaml as yaml
import sys

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
    'CHURN_LIMIT_QUOTIENT' : 65536
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
    'CHURN_LIMIT_QUOTIENT' : 32
}

config = minimal if data['eth2_base_config'] == 'minimal' else mainnet

print(f"""# Merge devnet preset

# Extends the minimal preset
PRESET_BASE: "{config['CONFIG_NAME']}"

# Genesis
# ---------------------------------------------------------------
# [customized]
MIN_GENESIS_ACTIVE_VALIDATOR_COUNT: 64
# Jan 3, 2020
MIN_GENESIS_TIME: 1606824000
# Highest byte set to 0x01 to avoid collisions with mainnet versioning
GENESIS_FORK_VERSION: {data['eth2_fork_version']}
# [customized] Faster to spin up testnets, but does not give validator reasonable warning time for genesis
GENESIS_DELAY: {data['eth2_genesis_delay']}


# Forking
# ---------------------------------------------------------------
# Values provided for illustrative purposes.
# Individual tests/testnets may set different values.

# Altair
ALTAIR_FORK_VERSION: 0x01000001
ALTAIR_FORK_EPOCH: 0
# Merge
MERGE_FORK_VERSION: 0x02000001
MERGE_FORK_EPOCH: 0
# Sharding
SHARDING_FORK_VERSION: 0x03000001
SHARDING_FORK_EPOCH: 18446744073709551615

# TBD, 2**32 is a placeholder. Merge transition approach is in active R&D.
MIN_ANCHOR_POW_BLOCK_DIFFICULTY: 4294967296


# Time parameters
# ---------------------------------------------------------------
# [customized] Faster for testing purposes
SECONDS_PER_SLOT: {config['SECONDS_PER_SLOT']}
# 14 (estimate from Eth1 mainnet)
SECONDS_PER_ETH1_BLOCK: {config['SECONDS_PER_SLOT']}
# 2**8 (= 256) epochs
MIN_VALIDATOR_WITHDRAWABILITY_DELAY: 256
# [customized] higher frequency of committee turnover and faster time to acceptable voluntary exit
SHARD_COMMITTEE_PERIOD: {config['SHARD_COMMITTEE_PERIOD']}
# [customized] process deposits more quickly, but insecure
ETH1_FOLLOW_DISTANCE: {config['ETH1_FOLLOW_DISTANCE']}


# Validator cycle
# ---------------------------------------------------------------
# 2**2 (= 4)
INACTIVITY_SCORE_BIAS: 4
# 2**4 (= 16)
INACTIVITY_SCORE_RECOVERY_RATE: 16
# 2**4 * 10**9 (= 16,000,000,000) Gwei
EJECTION_BALANCE: 16000000000
# 2**2 (= 4)
MIN_PER_EPOCH_CHURN_LIMIT: 4
# [customized] scale queue churn at much lower validator counts for testing
CHURN_LIMIT_QUOTIENT: {config['CHURN_LIMIT_QUOTIENT']}

# Deposit contract
# ---------------------------------------------------------------
# Execution layer chain
DEPOSIT_CHAIN_ID: {data['chain_id']}
DEPOSIT_NETWORK_ID: {data['chain_id']}
# Allocated in Execution-layer genesis
DEPOSIT_CONTRACT_ADDRESS: {data['deposit_contract_address']}
""")
