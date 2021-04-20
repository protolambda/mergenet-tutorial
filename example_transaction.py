from web3 import Web3
import json
import ruamel.yaml as yaml

provider = Web3.HTTPProvider('http://localhost:8545')
w3 = Web3(provider)

w3.eth.account.enable_unaudited_hdwallet_features()

with open("mergenet.yaml") as stream:
    data = yaml.safe_load(stream)

src_acct = w3.eth.account.from_mnemonic(
    data['mnemonic'], account_path=list(data['eth1_premine'].keys())[0], passphrase='')

dest_acct = w3.eth.account.from_mnemonic(
    data['mnemonic'], account_path=list(data['eth1_premine'].keys())[1], passphrase='')

transaction = {
    'to': dest_acct.address,
    'value': w3.toWei(1, 'ether'),
    'gas': 21000,
    'gasPrice': 4,
    'nonce': 0,
    'chainId': int(data['chain_id'])
}

print("signing transaction:")
print(json.dumps(transaction, indent="  "))

signed_transaction = src_acct.sign_transaction(transaction)

tx_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
print("tx hash: ", tx_hash)
