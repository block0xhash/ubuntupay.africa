import os
from web3 import Web3
from eth_account import Account
from dotenv import load_dotenv

# Load your specific keys
load_dotenv(dotenv_path="../trust-oracle/.env")

RPC_URL = "https://rpc-amoy.polygon.technology"
# THE CORRECT AMOY USDC ADDRESS
USDC_ADDR = Web3.to_checksum_address("0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582")
# YOUR DEPLOYED CONTRACT
GATE_ADDR = Web3.to_checksum_address("0x1373A4c5779536A7265a5a4EC70Bc288A208581A")
AGENT_KEY = os.getenv("DEPLOYER_PRIVATE_KEY")

w3 = Web3(Web3.HTTPProvider(RPC_URL))
agent = Account.from_key(AGENT_KEY)

print(f"Fixing permission for Agent: {agent.address}")

# Minimal ERC20 ABI for Approve and Balance
abi = [
    {"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},
    {"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
]

usdc = w3.eth.contract(address=USDC_ADDR, abi=abi)

# Check if agent has USDC first
bal = usdc.functions.balanceOf(agent.address).call()
print(f"Current Agent Balance: {bal / 10**6} USDC")

if bal == 0:
    print("🚨 ERROR: Agent has 0 USDC. Go to https://faucet.circle.com/ to fund 0x1525...EFe")
else:
    # Grant Infinite Allowance (2^256 - 1)
    tx = usdc.functions.approve(GATE_ADDR, 2**256 - 1).build_transaction({
        'from': agent.address,
        'nonce': w3.eth.get_transaction_count(agent.address),
        'gas': 100000,
        'gasPrice': w3.eth.gas_price,
        'chainId': 80002
    })

    signed = w3.eth.account.sign_transaction(tx, AGENT_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    print(f"✅ Approval successful! Hash: {tx_hash.hex()}")
    print(f"Check here: https://amoy.polygonscan.com/tx/{tx_hash.hex()}")
