"""
seed_vaults.py — pre-register Nokia test numbers on TrustGate.sol
Run once after deploying the updated contract.

Usage:
    cd ~/UbuntuPay/trust-oracle
    source ../venv/bin/activate
    source ../.env
    python3 seed_vaults.py
"""
import os, sys
sys.path.insert(0, "/home/bothwell/UbuntuPay/trust-oracle")
import blockchain
from nokia_client import check as nokia_check

DEMO_PIN = "1234"

TEST_NUMBERS = [
    "+99999991001",   # Joseph — Nairobi sender
    "+99999991002",   # John   — Lagos recipient
]

def main():
    print("Ubuntu Pay — Vault Registration Seeder")
    print("=" * 50)

    for phone in TEST_NUMBERS:
        print(f"\nRegistering {phone}...")
        try:
            # Get real Nokia signals for this test number
            sig   = nokia_check(phone)
            vault = blockchain.phone_to_address(
                phone, sig.network_id, sig.hardware_id, DEMO_PIN
            )
            phone_hash = blockchain.phone_to_hash(phone).hex()

            print(f"  Nokia IMSI:   {sig.network_id}")
            print(f"  Nokia IMEI:   {sig.hardware_id}")
            print(f"  Vault:        {vault}")
            print(f"  Phone hash:   0x{phone_hash[:16]}...")

            # Check if already registered
            existing = blockchain.contract.functions.vaults(
                blockchain.phone_to_hash(phone)
            ).call()
            if existing != "0x" + "0" * 40:
                print(f"  Already registered: {existing}")
                continue

            # Register on-chain
            import asyncio
            tx = asyncio.run(
                blockchain.register_vault_on_chain(phone, vault)
            )
            print(f"  Registered! tx: {tx[:20]}...")

        except Exception as e:
            print(f"  ERROR: {e}")

    print("\nDone.")

if __name__ == "__main__":
    main()
