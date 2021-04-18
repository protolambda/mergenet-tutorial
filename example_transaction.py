from web3.auto import w3
import json
import ruamel.yaml as yaml

w3.eth.account.enable_unaudited_hdwallet_features()

with open("mergenet.yaml") as stream:
    data = yaml.safe_load(stream)

src_acct = w3.eth.account.from_mnemonic(
    data['mnemonic'], account_path=data['eth1_premine'].keys()[0], passphrase='')

dest_acct = w3.eth.account.from_mnemonic(
    data['mnemonic'], account_path=data['eth1_premine'].keys()[1], passphrase='')

transaction = {
    'to': dest_acct.address,
    'value': 1 * 1e18,
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
