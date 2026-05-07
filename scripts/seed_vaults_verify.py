
import sys
sys.path.insert(0, "/home/bothwell/UbuntuPay/trust-oracle")
import blockchain

for phone in ["+99999991001", "+99999991002"]:
    h = blockchain.phone_to_hash(phone)
    vault = blockchain.contract.functions.vaults(h).call()
    print(f"{phone} -> {vault}")
