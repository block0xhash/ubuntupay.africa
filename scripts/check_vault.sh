python3 << 'EOF'
import os, sys
sys.path.insert(0, os.path.expanduser("~/UbuntuPay/trust-oracle"))
import blockchain

joseph = "0xFfc0Ec2c6741C2c4a7680A08b96B48c49d35Ecdb"

# TrustGate internal balance
bal = blockchain.contract.functions.balances(joseph).call() / 10**6
print(f"Joseph vault balance: {bal} USDC")

# Check if contract has a lockedBalance or escrow function
# Print all available functions
funcs = [f['name'] for f in blockchain.contract.abi if f.get('type') == 'function']
print(f"\nContract functions: {funcs}")
EOF
