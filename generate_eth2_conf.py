import ruamel.yaml as yaml

with open("mergenet.yaml") as stream:
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

f"""
# Merge devnet preset

# TODO some clients need either the mainnet/minimal name for base config values (Lighthouse/Nimbus?)
CONFIG_NAME: "{config['CONFIG_NAME']}"

# Misc
# ---------------------------------------------------------------
MAX_COMMITTEES_PER_SLOT: {config['MAX_COMMITTEES_PER_SLOT']}
TARGET_COMMITTEE_SIZE: {config['TARGET_COMMITTEE_SIZE']}
MAX_VALIDATORS_PER_COMMITTEE: 2048
MIN_PER_EPOCH_CHURN_LIMIT: 4
CHURN_LIMIT_QUOTIENT: 65536
SHUFFLE_ROUND_COUNT: {config['SHUFFLE_ROUND_COUNT']}
MIN_GENESIS_ACTIVE_VALIDATOR_COUNT: {config['MIN_GENESIS_ACTIVE_VALIDATOR_COUNT']}
# left unmodified, eth1 timestamp is used instead, modify genesis-delay for eth2
MIN_GENESIS_TIME: 1606824000

HYSTERESIS_QUOTIENT: 4
HYSTERESIS_DOWNWARD_MULTIPLIER: 1
HYSTERESIS_UPWARD_MULTIPLIER: 5


# Fork Choice
# ---------------------------------------------------------------
SAFE_SLOTS_TO_UPDATE_JUSTIFIED: 8


# Validator
# ---------------------------------------------------------------
ETH1_FOLLOW_DISTANCE: {config['ETH1_FOLLOW_DISTANCE']}
TARGET_AGGREGATORS_PER_COMMITTEE: 16
RANDOM_SUBNETS_PER_VALIDATOR: 1
EPOCHS_PER_RANDOM_SUBNET_SUBSCRIPTION: 256
# set equal to SECONDS_PER_SLOT for merge-net
SECONDS_PER_ETH1_BLOCK: {config['SECONDS_PER_SLOT']}


# Deposit contract
# ---------------------------------------------------------------
# Execution layer chain
DEPOSIT_CHAIN_ID: {data['chain_id']}
DEPOSIT_NETWORK_ID: {data['chain_id']}
# Allocated in Execution-layer genesis
DEPOSIT_CONTRACT_ADDRESS: {data['deposit_contract_address']}


# Gwei values
# ---------------------------------------------------------------
MIN_DEPOSIT_AMOUNT: 1000000000
MAX_EFFECTIVE_BALANCE: 32000000000
EJECTION_BALANCE: 16000000000
EFFECTIVE_BALANCE_INCREMENT: 1000000000


# Initial values
# ---------------------------------------------------------------
GENESIS_FORK_VERSION: "{data['eth2_fork_version']}"

BLS_WITHDRAWAL_PREFIX: 0x00


# Time parameters
# ---------------------------------------------------------------
GENESIS_DELAY: {data['eth2_genesis_delay']}
SECONDS_PER_SLOT: {config['SECONDS_PER_SLOT']}
MIN_ATTESTATION_INCLUSION_DELAY: 1
SLOTS_PER_EPOCH: {config['SLOTS_PER_EPOCH']}
MIN_SEED_LOOKAHEAD: 1
MAX_SEED_LOOKAHEAD: 4
EPOCHS_PER_ETH1_VOTING_PERIOD: {config['EPOCHS_PER_ETH1_VOTING_PERIOD']}
SLOTS_PER_HISTORICAL_ROOT: {config['SLOTS_PER_HISTORICAL_ROOT']}
MIN_VALIDATOR_WITHDRAWABILITY_DELAY: 256
SHARD_COMMITTEE_PERIOD: {config['SHARD_COMMITTEE_PERIOD']}
MIN_EPOCHS_TO_INACTIVITY_PENALTY: 4


# State vector lengths
# ---------------------------------------------------------------
EPOCHS_PER_HISTORICAL_VECTOR: {config['EPOCHS_PER_HISTORICAL_VECTOR']}
EPOCHS_PER_SLASHINGS_VECTOR: {config['EPOCHS_PER_SLASHINGS_VECTOR']}
HISTORICAL_ROOTS_LIMIT: {config['SLOTS_PER_HISTORICAL_ROOT']}
VALIDATOR_REGISTRY_LIMIT: 1099511627776


# Reward and penalty quotients
# ---------------------------------------------------------------
BASE_REWARD_FACTOR: 64
WHISTLEBLOWER_REWARD_QUOTIENT: 512
PROPOSER_REWARD_QUOTIENT: 8
INACTIVITY_PENALTY_QUOTIENT: {config['INACTIVITY_PENALTY_QUOTIENT']}
MIN_SLASHING_PENALTY_QUOTIENT: {config['MIN_SLASHING_PENALTY_QUOTIENT']}
PROPORTIONAL_SLASHING_MULTIPLIER: {config['PROPORTIONAL_SLASHING_MULTIPLIER']}


# Max operations per block
# ---------------------------------------------------------------
MAX_PROPOSER_SLASHINGS: 16
MAX_ATTESTER_SLASHINGS: 2
MAX_ATTESTATIONS: 128
MAX_DEPOSITS: 16
MAX_VOLUNTARY_EXITS: 16


# Signature domains
# ---------------------------------------------------------------
DOMAIN_BEACON_PROPOSER: 0x00000000
DOMAIN_BEACON_ATTESTER: 0x01000000
DOMAIN_RANDAO: 0x02000000
DOMAIN_DEPOSIT: 0x03000000
DOMAIN_VOLUNTARY_EXIT: 0x04000000
DOMAIN_SELECTION_PROOF: 0x05000000
DOMAIN_AGGREGATE_AND_PROOF: 0x06000000
"""