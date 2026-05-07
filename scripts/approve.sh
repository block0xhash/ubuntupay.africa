
source ~/UbuntuPay/.env

python3 << 'EOF'
import os
from web3 import Web3
from eth_account import Account

w3    = Web3(Web3.HTTPProvider(os.getenv("POLYGON_RPC_URL")))
key   = os.getenv("DEPLOYER_PRIVATE_KEY")
agent = Account.from_key(key).address
USDC  = "0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582"
GATE  = os.getenv("TRUST_GATE_ADDRESS")

print(f"Agent: {agent}")
print(f"Gate:  {GATE}")

abi = [{"name":"approve","type":"function","stateMutability":"nonpayable",
        "inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],
        "outputs":[{"name":"","type":"bool"}]}]

usdc = w3.eth.contract(address=USDC, abi=abi)

tx = usdc.functions.approve(
    Web3.to_checksum_address(GATE),
    2**256 - 1
).build_transaction({
    "from":     agent,
    "nonce":    w3.eth.get_transaction_count(agent),
    "gas":      100000,
    "gasPrice": w3.eth.gas_price,
    "chainId":  80002
})
signed  = w3.eth.account.sign_transaction(tx, key)
tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction).hex()
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print(f"Status: {'SUCCESS' if receipt.status == 1 else 'FAILED'}")
print(f"TX:     https://amoy.polygonscan.com/tx/{tx_hash}")
EOF
