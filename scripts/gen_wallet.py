"""
Ubuntu Pay — gen_wallet.py
Generates Ethereum wallets for deployer and oracle.

Run: python3 scripts/gen_wallet.py
Then fund deployer at: https://faucet.polygon.technology
"""
from eth_account import Account
import secrets

def gen():
    key  = "0x" + secrets.token_hex(32)
    acct = Account.from_key(key)
    return key, acct.address

print("\n════════════════════════════════════════")
print("Ubuntu Pay — Wallet Generator")
print("⚠  Save these keys. Never share them.")
print("════════════════════════════════════════\n")

dk, da = gen()
ok, oa = gen()

print(f"DEPLOYER\n  Address: {da}\n  Key:     {dk}\n")
print(f"ORACLE\n  Address: {oa}\n  Key:     {ok}\n")
print("Add to .env:")
print(f"  DEPLOYER_PRIVATE_KEY={dk}")
print(f"  ORACLE_PRIVATE_KEY={ok}")
print(f"\nFund DEPLOYER at: https://faucet.polygon.technology")
print(f"  Paste: {da}")
print("════════════════════════════════════════\n")
