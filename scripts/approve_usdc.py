
# approve TrustGate.sol to spend agents USDC. This is a standard ERC-20 allowance requirement.

import os
from web3 import Web3
from eth_account import Account
from dotenv import load_dotenv

load_dotenv(dotenv_path="../trust-oracle/.env")

RPC_URL = "https://rpc-amoy.polygon.technology"
USDC_ADDR = Web3.to_checksum_address("0x41E94404177041BC77Ba9bede0C69e7072f9247B")
GATE_ADDR = Web3.to_checksum_address(os.getenv("TRUST_GATE_ADDRESS"))
AGENT_KEY = os.getenv("DEPLOYER_PRIVATE_KEY")

w3 = Web3(Web3.HTTPProvider(RPC_URL))
agent = Account.from_key(AGENT_KEY)

# Simple ERC20 Approve ABI
abi = [{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]

usdc = w3.eth.contract(address=USDC_ADDR, abi=abi)
tx = usdc.functions.approve(GATE_ADDR, 10**30).build_transaction({
    'from': agent.address,
    'nonce': w3.eth.get_transaction_count(agent.address),
    'gas': 100000,
    'gasPrice': w3.eth.gas_price,
    'chainId': 80002
})

signed = w3.eth.account.sign_transaction(tx, AGENT_KEY)
tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
print(f"Approval Transaction Sent: https://amoy.polygonscan.com/tx/{tx_hash.hex()}")
