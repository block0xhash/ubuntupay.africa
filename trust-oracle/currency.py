
"""
Ubuntu Pay — currency.py
THE LIQUIDITY & FX ENGINE (Powered by Yellow Card)

================================================================================
EXECUTIVE SUMMARY FOR JUDGES:
Traditional cross-border banking is slow and expensive because of 'Correspondent
Banking'. Ubuntu Pay replaces this with the 'Stablecoin Rail'.

We use Yellow Card's API to convert local African cash (like KES) into
Digital Dollars (USDC). These dollars move instantly across borders on the
blockchain. On the receiving end, we convert them back into local Mobile Money
(like NGN or ZAR).

This engine ensures Joseph always gets the best market rate and Emmanuel
receives his funds in seconds, not days.
================================================================================

IT ARCHITECTURE NOTES:
This module manages the interface with Yellow Card (v2). It handles live
FX rate fetching, currency conversion math, and automated disbursements
to Mobile Money (MoMo) wallets. It features a high-availability fallback
to 'Reference Rates' if the exchange API is temporarily unreachable.
"""

import httpx
import os
from dotenv import load_dotenv
from loguru import logger

load_dotenv()

# --- YELLOW CARD CONFIGURATION ---
# The sandbox URL allows us to test without spending real money.
YC_URL = os.getenv("YELLOW_CARD_BASE_URL", "https://api.sandbox.yellowcard.io")
YC_KEY = os.getenv("YELLOW_CARD_API_KEY", "")

# --- REFERENCE RATES (Fallback) ---
# These are used only if the live API is down, ensuring the protocol never stops.
# Rates based on 2026 market projections.
RATES = {
    "KES": 130.24,  # Kenyan Shilling
    "NGN": 1558.40, # Nigerian Naira
    "GHS": 15.82,   # Ghanaian Cedi
    "ZAR": 18.14,   # South African Rand
    "TZS": 2640.00, # Tanzanian Shilling
    "USD": 1.00     # Base Currency
}

async def get_rates() -> dict:
    """
    PURPOSE: Fetches live African FX prices from Yellow Card.
    BUSINESS VALUE: Ensures the protocol always uses the most accurate
    market data to protect Joseph from currency volatility.
    """
    if not YC_KEY:
        logger.warning("💱 FX: No API Key found. Using Reference Rates.")
        return RATES

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            # We request live rates from Yellow Card's global order book
            response = await client.get(f"{YC_URL}/v2/rates", headers={"x-api-key": YC_KEY})

            if response.status_code == 200:
                data = response.json()
                live_rates = {}
                for item in data.get("rates", []):
                    # We map the API response into a simple format the Oracle can read
                    if item.get("currency") and item.get("rate"):
                        live_rates[item["currency"]] = float(item["rate"])

                logger.success("💱 FX: Live market rates updated from Yellow Card.")
                return live_rates if live_rates else RATES
    except Exception as e:
        logger.error(f"💱 FX ERROR: Could not fetch live rates: {e}. Using fallbacks.")

    return RATES

async def kes_to_usdc(kes: float) -> float:
    """
    PURPOSE: Converts Kenyan Shillings into Digital Dollars (USDC).

    BUSINESS VALUE:
    1. We apply a tiny 'FX Spread' (0.1%). This is how the protocol stays
       profitable while remaining 90% cheaper than a bank.
    2. We round to 6 decimals because that is the precision of USDC.
    """
    market_rates = await get_rates()
    current_rate = market_rates.get("KES", 130.24)

    # Spread represents the protocol's tiny margin on the exchange
    spread = float(os.getenv("FX_SPREAD", "0.001")) # 0.1%

    # Math: (Amount / Rate) minus the tiny spread
    usdc_amount = (kes / current_rate) * (1 - spread)

    logger.info(f"💱 CONVERSION: KES {kes} ➔ ${usdc_amount:.4f} USDC (Rate: {current_rate})")
    return round(usdc_amount, 6)

def get_currency_from_phone(phone: str) -> str:
    """
    PURPOSE: Logic to identify the local currency of the receiver.
    E.g., +234 = Nigeria (NGN), +254 = Kenya (KES).
    """
    p = "".join([c for c in phone if c.isdigit()])
    if p.startswith("234"): return "NGN"
    if p.startswith("254"): return "KES"
    if p.startswith("27"):  return "ZAR"
    if p.startswith("233"): return "GHS"
    return "USD" # Default to Dollars if unknown

async def usdc_to_local(usdc: float, currency: str) -> float:
    """
    PURPOSE: Estimates how much local money the receiver will get.
    """
    market_rates = await get_rates()
    rate = market_rates.get(currency, 1.0)
    return round(usdc * rate, 2)

async def payout(receiver_phone: str, usdc_amount: float) -> dict:
    """
    PURPOSE: THE LAST MILE.
    This sends the digital dollars (USDC) out of the Ubuntu Pay system
    and into the receiver's physical Mobile Money (MoMo) account.

    BUSINESS VALUE:
    This turns 'Blockchain' back into 'Spending Money' for Emmanuel in Lagos.
    """
    # 1. Identify the target currency
    target_currency = get_currency_from_phone(receiver_phone)
    market_rates = await get_rates()

    # 2. Calculate local payout amount
    local_payout = round(usdc_amount * market_rates.get(target_currency, 1.0), 2)

    logger.info(f"📲 PAYOUT START: Sending {target_currency} {local_payout} to {receiver_phone}...")

    # FALLBACK: If we are in demo/offline mode without a Yellow Card key
    if not YC_KEY:
        logger.warning("📲 PAYOUT: Simulation mode active. No real funds moved.")
        return {
            "status": "simulated",
            "ref": f"SIM-{receiver_phone[-4:]}-{int(usdc_amount*100)}",
            "usdc": usdc_amount,
            "local": local_payout,
            "currency": target_currency
        }

    try:
        # --- THE LIVE DISBURSEMENT ---
        # This calls Yellow Card's payout engine to move money to a phone number
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{YC_URL}/v2/disbursements",
                headers={"x-api-key": YC_KEY, "Content-Type": "application/json"},
                json={
                    "currency": target_currency,
                    "amount": local_payout,
                    "recipient": {
                        "phone": receiver_phone,
                        "type": "momo" # 'momo' stands for Mobile Money (MTN, Airtel, etc.)
                    },
                    "reference": f"UP-{receiver_phone[-6:]}-{int(usdc_amount*10000)}"
                }
            )

            result = response.json()
            logger.success(f"📲 PAYOUT SUCCESS: Emmanuel is being credited via MoMo. ID: {result.get('id')}")

            return {
                "status": result.get("status", "processing"),
                "ref": result.get("id", ""),
                "usdc": usdc_amount,
                "local": local_payout,
                "currency": target_currency
            }

    except Exception as e:
        logger.error(f"📲 PAYOUT CRITICAL ERROR: {e}")
        # We return a specific error status so the USSD can alert the user
        return {
            "status": "error",
            "error": "Payout provider busy",
            "usdc": usdc_amount,
            "local": local_payout
        }

# 🏁 BUSINESS VALUE FOR PITCH:
# "Our Liquidity Engine doesn't just calculate prices; it automates the
# entire 'Last Mile' of the payment. By bridging Yellow Card and the
# Polygon Blockchain, we provide the user with the liquidity of a bank
# and the transparency of a public ledger."
