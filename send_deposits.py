from web3 import Web3
import json
import ruamel.yaml as yaml
import os

testnet_name = os.environ['TESTNET_NAME']
validator_node_name = os.environ['VALIDATOR_NODE_NAME']

#Adjust this to your eth1 endpoint
provider = Web3.HTTPProvider('http://localhost:8545')

w3 = Web3(provider)

w3.eth.account.enable_unaudited_hdwallet_features()

with open("mergenet.yaml") as stream:
    data = yaml.safe_load(stream)

src_acct = w3.eth.account.from_mnemonic(
    data['mnemonic'], account_path=list(data['eth1_premine'].keys())[0], passphrase='')

nonce = w3.eth.getTransactionCount(src_acct.address)

deposit_data_path = testnet_name + "/private/" + validator_node_name + "/depositdata"
with open(deposit_data_path) as depositdata:
    for line in depositdata:
        depjson = json.loads(line)
        depdata = "0x22895118" +\
                  "0000000000000000000000000000000000000000000000000000000000000080"+\
                  "00000000000000000000000000000000000000000000000000000000000000e0"+\
                  "0000000000000000000000000000000000000000000000000000000000000120"+\
                  depjson['deposit_data_root']+\
                  "0000000000000000000000000000000000000000000000000000000000000030"+\
                  depjson['pubkey']+\
                  "00000000000000000000000000000000"+\
                  "0000000000000000000000000000000000000000000000000000000000000020"+\
                  depjson['withdrawal_credentials']+\
                  "0000000000000000000000000000000000000000000000000000000000000060"+\
                  depjson['signature']
        transaction = {
            'to': data['deposit_contract_address'],
            'value': w3.toWei(depjson['value'], 'gwei'),
            'gas': 95000,
            'gasPrice': 4,
            'nonce' : nonce,
            'chainId': int(data['chain_id']),
            'data': depdata
        }
        nonce += 1

        signed_transaction = src_acct.sign_transaction(transaction)
        tx_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
        print("Sent deposit for pubkey: {}".format(depjson['pubkey']))
        print("tx hash: {}.".format(tx_hash.hex()))

