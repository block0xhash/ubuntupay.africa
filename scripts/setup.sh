#!/bin/bash
# Ubuntu Pay — setup.sh
# Run this from ~/UbuntuPay after cloning/downloading the files
# It creates every file in the right folder
# Usage: bash setup.sh

set -e  # stop on any error

echo ""
echo "════════════════════════════════════════"
echo "Ubuntu Pay — Project Setup"
echo "════════════════════════════════════════"

# Make sure we are in the right place
cd ~/UbuntuPay

# Create folders if they don't exist
mkdir -p trust-oracle smart-contracts ussd-gateway dashboard scripts

echo "✓ Folders ready"

# ── trust-oracle/database.py ──────────────────────────────
cat > trust-oracle/database.py << 'PYEOF'
"""
Ubuntu Pay — database.py
SQLite database. One file. Zero config. Just works.
"""
import sqlite3
import aiosqlite
import os
from dotenv import load_dotenv

load_dotenv()
DB = os.getenv("DATABASE_PATH", "./ubuntu_pay.db")

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS checks (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            sender          TEXT NOT NULL,
            receiver        TEXT,
            amount_usdc     REAL,
            sim_swapped     INTEGER,
            device_changed  INTEGER,
            number_verified INTEGER,
            kyc_score       REAL,
            roaming         INTEGER,
            trust_score     INTEGER,
            decision        TEXT,
            reasoning       TEXT,
            ms              INTEGER,
            ts              DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS transfers (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            tx_hash     TEXT,
            sender      TEXT NOT NULL,
            receiver    TEXT NOT NULL,
            kes         REAL,
            usdc        REAL,
            score       INTEGER,
            status      TEXT,
            ts          DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()
    print(f"✓ Database ready: {DB}")

async def save_check(d: dict) -> int:
    async with aiosqlite.connect(DB) as db:
        cur = await db.execute("""
            INSERT INTO checks
              (sender, receiver, amount_usdc, sim_swapped, device_changed,
               number_verified, kyc_score, roaming, trust_score, decision, reasoning, ms)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            d.get("sender"), d.get("receiver"), d.get("amount_usdc"),
            int(d.get("sim_swapped", 0)), int(d.get("device_changed", 0)),
            int(d.get("number_verified", 1)), d.get("kyc_score"),
            int(d.get("roaming", 0)), d.get("trust_score"),
            d.get("decision"), d.get("reasoning"), d.get("ms")
        ))
        await db.commit()
        return cur.lastrowid

async def save_transfer(d: dict) -> int:
    async with aiosqlite.connect(DB) as db:
        cur = await db.execute("""
            INSERT INTO transfers (tx_hash, sender, receiver, kes, usdc, score, status)
            VALUES (?,?,?,?,?,?,?)
        """, (
            d.get("tx_hash"), d["sender"], d["receiver"],
            d.get("kes"), d.get("usdc"), d.get("score"), d.get("status", "pending")
        ))
        await db.commit()
        return cur.lastrowid

async def get_recent(limit: int = 20) -> list:
    async with aiosqlite.connect(DB) as db:
        db.row_factory = aiosqlite.Row
        cur = await db.execute(
            "SELECT * FROM checks ORDER BY ts DESC LIMIT ?", (limit,)
        )
        rows = await cur.fetchall()
        return [dict(r) for r in rows]

async def get_stats() -> dict:
    async with aiosqlite.connect(DB) as db:
        total   = (await (await db.execute("SELECT COUNT(*) FROM checks")).fetchone())[0]
        blocked = (await (await db.execute("SELECT COUNT(*) FROM checks WHERE decision='BLOCK'")).fetchone())[0]
        avg     = (await (await db.execute("SELECT AVG(trust_score) FROM checks WHERE trust_score IS NOT NULL")).fetchone())[0]
        txs     = (await (await db.execute("SELECT COUNT(*) FROM transfers")).fetchone())[0]
    return {
        "total":   total,
        "blocked": blocked,
        "allowed": total - blocked,
        "avg_score": round(avg or 0, 1),
        "transfers": txs
    }
PYEOF

echo "✓ trust-oracle/database.py"

# ── trust-oracle/nokia_client.py ─────────────────────────
cat > trust-oracle/nokia_client.py << 'PYEOF'
"""
Ubuntu Pay — nokia_client.py
All 5 Nokia CAMARA APIs firing in parallel.

Without NOKIA_API_KEY → simulation mode (demo still works perfectly)
With NOKIA_API_KEY    → real network data from real African phones

Get your free key: networkascode.nokia.io/auth/sign-up
"""
import asyncio
import os
import time
from dataclasses import dataclass
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

try:
    import network_as_code as nac
    _client = nac.NetworkAsCodeClient(api_key=os.getenv("NOKIA_API_KEY", ""))
    REAL = True
    print("✓ Nokia Network as Code — REAL API connected")
except Exception as e:
    REAL = False
    print(f"⚠ Nokia SDK: {e}")
    print("  Running in SIMULATION mode")

@dataclass
class Signals:
    sim_swapped:     bool  = False
    sim_hours_ago:   int   = 999
    rec_sim_swapped: bool  = False
    device_changed:  bool  = False
    number_verified: bool  = True
    kyc_score:       float = 0.85
    online:          bool  = True
    roaming:         bool  = False
    country:         str   = "KE"
    ms:              int   = 0
    error:           Optional[str] = None

async def _sim_swap(phone: str) -> dict:
    """API 1 — Was this SIM swapped in the last 72 hours?"""
    if not REAL:
        bad = phone.endswith("99") or "swap" in phone.lower()
        return {"swapped": bad, "hours": 2 if bad else 94}
    d = _client.devices.get(phone_number=phone)
    r = await d.get_sim_swap_date()
    return {"swapped": r.swapped_in_period(hours=72), "hours": 72}

async def _device(phone: str) -> dict:
    """API 2 — Is this the same physical device?"""
    if not REAL:
        return {"changed": phone.endswith("88")}
    d = _client.devices.get(phone_number=phone)
    r = await d.get_connectivity_status()
    return {"changed": getattr(r, "device_swapped", False)}

async def _number(phone: str) -> dict:
    """API 3 — Does this device own this number? No OTP needed."""
    if not REAL:
        return {"verified": not phone.endswith("77")}
    d = _client.devices.get(phone_number=phone)
    r = await d.verify_number(access_token="")
    return {"verified": getattr(r, "device_phone_number_verified", True)}

async def _kyc(phone: str) -> dict:
    """API 4 — Does identity match SIM registration?"""
    if not REAL:
        score = 0.28 if phone.endswith("99") else 0.96
        return {"score": score}
    d = _client.devices.get(phone_number=phone)
    r = await d.get_kyc_match()
    return {"score": getattr(r, "score", 0.85)}

async def _status(phone: str) -> dict:
    """API 5 — Is device online? Roaming unexpectedly?"""
    if not REAL:
        roam = phone.endswith("55")
        return {"online": True, "roaming": roam, "country": "ZA" if roam else "KE"}
    d = _client.devices.get(phone_number=phone)
    r = await d.get_connectivity_status()
    return {
        "online":  bool(getattr(r, "connectivity", True)),
        "roaming": bool(getattr(r, "roaming", False)),
        "country": str(getattr(r, "country_code", "KE"))
    }

async def check(sender: str, receiver: str) -> Signals:
    """
    Fire all 5 Nokia APIs simultaneously for both sender and receiver.
    asyncio.gather = parallel. ~200ms total not 5 x 200ms.
    This is why Ubuntu Pay needs Nokia — no other source has SIM swap data.
    """
    t = time.monotonic()
    results = await asyncio.gather(
        _sim_swap(sender),
        _sim_swap(receiver),
        _device(sender),
        _number(sender),
        _kyc(sender),
        _status(sender),
        return_exceptions=True
    )
    ms = int((time.monotonic() - t) * 1000)

    def safe(r, key, default):
        if isinstance(r, Exception):
            return default
        return r.get(key, default)

    r1s, r1r, r2, r3, r4, r5 = results
    return Signals(
        sim_swapped     = safe(r1s, "swapped", False),
        sim_hours_ago   = safe(r1s, "hours",   999),
        rec_sim_swapped = safe(r1r, "swapped", False),
        device_changed  = safe(r2,  "changed", False),
        number_verified = safe(r3,  "verified", True),
        kyc_score       = safe(r4,  "score",   0.85),
        online          = safe(r5,  "online",  True),
        roaming         = safe(r5,  "roaming", False),
        country         = safe(r5,  "country", "KE"),
        ms              = ms
    )
PYEOF

echo "✓ trust-oracle/nokia_client.py"

# ── trust-oracle/ai_agent.py ─────────────────────────────
cat > trust-oracle/ai_agent.py << 'PYEOF'
"""
Ubuntu Pay — ai_agent.py
Gemini reads Nokia signals and returns a trust score 0-100.

Get free key: aistudio.google.com → Get API Key → Create API key
"""
import google.generativeai as genai
import json
import os
from dotenv import load_dotenv
from nokia_client import Signals

load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY", ""))

model = genai.GenerativeModel(
    model_name="gemini-1.5-flash",
    generation_config=genai.GenerationConfig(
        response_mime_type="application/json",
        max_output_tokens=200,
        temperature=0.1
    )
)

PROMPT = """You are the Ubuntu Pay Trust Oracle AI.
Analyse Nokia CAMARA network signals for a mobile payment in Africa.
Return ONLY valid JSON:
{{"score": <0-100>, "decision": "<ALLOW|STEP_UP|BLOCK>", "reasoning": "<one sentence>"}}

Rules:
- score >= 70 → ALLOW
- score 50-69 → STEP_UP
- score < 50  → BLOCK
- SIM swapped in 72hrs → score=0, BLOCK (overrides everything)

Nokia signals:
Sender SIM swapped:     {sim_swapped}
Sender device changed:  {device_changed}
Number verified:        {number_verified}
KYC score:             {kyc_score:.2f}
Roaming:               {roaming}
Country:               {country}
Receiver SIM swapped:  {rec_sim_swapped}
Amount: ${amount:.4f} USDC  Type: {tx_type}  API time: {ms}ms"""


async def score(signals: Signals, amount: float, tx_type: str = "cross_border") -> dict:
    # Hard block — don't even call Gemini
    if signals.sim_swapped:
        return {
            "score":    0,
            "decision": "BLOCK",
            "reasoning": "Sender SIM replaced within 72 hours — primary indicator of account takeover fraud."
        }

    try:
        resp   = model.generate_content(PROMPT.format(
            sim_swapped     = signals.sim_swapped,
            device_changed  = signals.device_changed,
            number_verified = signals.number_verified,
            kyc_score       = signals.kyc_score,
            roaming         = signals.roaming,
            country         = signals.country,
            rec_sim_swapped = signals.rec_sim_swapped,
            amount          = amount,
            tx_type         = tx_type,
            ms              = signals.ms
        ))
        result = json.loads(resp.text)
        result["score"] = max(0, min(100, int(result.get("score", 50))))
        s = result["score"]
        result["decision"] = "ALLOW" if s >= 70 else "STEP_UP" if s >= 50 else "BLOCK"
        return result
    except Exception as e:
        return {
            "score":    45,
            "decision": "STEP_UP",
            "reasoning": f"AI temporarily unavailable — conservative score applied. ({str(e)[:60]})"
        }
PYEOF

echo "✓ trust-oracle/ai_agent.py"

# ── trust-oracle/currency.py ─────────────────────────────
cat > trust-oracle/currency.py << 'PYEOF'
"""
Ubuntu Pay — currency.py
Yellow Card API for live African rates.
Falls back to hardcoded rates if API not available.
"""
import httpx
import os
from dotenv import load_dotenv

load_dotenv()

YC_URL = os.getenv("YELLOW_CARD_BASE_URL", "https://api.sandbox.yellowcard.io")
YC_KEY = os.getenv("YELLOW_CARD_API_KEY", "")

RATES = {
    "KES": 130.24,
    "NGN": 1558.40,
    "GHS": 15.82,
    "ZAR": 18.14,
    "TZS": 2640.00,
    "USD": 1.00
}

async def get_rates() -> dict:
    if not YC_KEY:
        return RATES
    try:
        async with httpx.AsyncClient(timeout=5.0) as c:
            r = await c.get(f"{YC_URL}/v2/rates", headers={"x-api-key": YC_KEY})
            if r.status_code == 200:
                data  = r.json()
                rates = {}
                for item in data.get("rates", []):
                    if item.get("currency") and item.get("rate"):
                        rates[item["currency"]] = float(item["rate"])
                return rates if rates else RATES
    except Exception:
        pass
    return RATES

async def kes_to_usdc(kes: float) -> float:
    r    = await get_rates()
    rate = r.get("KES", 130.24)
    spread = float(os.getenv("FX_SPREAD", "0.001"))
    return round((kes / rate) * (1 - spread), 6)

async def usdc_to_local(usdc: float, currency: str) -> float:
    r = await get_rates()
    return round(usdc * r.get(currency, 1.0), 2)

async def payout(receiver_phone: str, usdc: float, currency: str = "NGN") -> dict:
    r     = await get_rates()
    local = round(usdc * r.get(currency, 1.0), 2)
    if not YC_KEY:
        return {
            "status": "simulated",
            "ref":    f"SIM-{receiver_phone[-4:]}-{int(usdc*100)}",
            "usdc":   usdc,
            "local":  local,
            "currency": currency
        }
    try:
        async with httpx.AsyncClient(timeout=30.0) as c:
            res = await c.post(
                f"{YC_URL}/v2/disbursements",
                headers={"x-api-key": YC_KEY, "Content-Type": "application/json"},
                json={
                    "currency": currency,
                    "amount":   local,
                    "recipient": {"phone": receiver_phone, "type": "momo"},
                    "reference": f"UP-{receiver_phone[-6:]}-{int(usdc*10000)}"
                }
            )
            d = res.json()
            return {"status": d.get("status", "processing"), "ref": d.get("id", ""),
                    "usdc": usdc, "local": local, "currency": currency}
    except Exception as e:
        return {"status": "error", "error": str(e), "usdc": usdc, "local": local}
PYEOF

echo "✓ trust-oracle/currency.py"

# ── trust-oracle/blockchain.py ───────────────────────────
cat > trust-oracle/blockchain.py << 'PYEOF'
"""
Ubuntu Pay — blockchain.py
Polygon Mumbai testnet.

Day 1: simulates tx hash (no wallet needed yet)
Day 2: deploy contract, add keys to .env, get real hashes on polygonscan
"""
import os
import json
import hashlib
import time
from dotenv import load_dotenv
from loguru import logger

load_dotenv()

RPC   = os.getenv("POLYGON_RPC_URL", "https://rpc-mumbai.maticvigil.com")
CHAIN = int(os.getenv("POLYGON_CHAIN_ID", "80001"))
KEY   = os.getenv("ORACLE_PRIVATE_KEY", "")
GATE  = os.getenv("TRUST_GATE_ADDRESS", "")
ABI_F = os.path.join(os.path.dirname(__file__), "TrustGate.abi.json")

try:
    from web3 import Web3
    from eth_account import Account
    w3 = Web3(Web3.HTTPProvider(RPC))
    CONNECTED = w3.is_connected()
    if CONNECTED:
        logger.info(f"✓ Polygon Mumbai connected (block #{w3.eth.block_number})")
    else:
        logger.warning("⚠ Cannot reach Polygon Mumbai — simulating blockchain")
except Exception as e:
    CONNECTED = False
    logger.warning(f"⚠ Web3: {e} — simulating blockchain")

ORACLE_ADDR = None
contract    = None

if KEY and CONNECTED:
    try:
        ORACLE_ADDR = Account.from_key(KEY).address
        logger.info(f"✓ Oracle wallet: {ORACLE_ADDR}")
    except Exception as e:
        logger.warning(f"⚠ Wallet: {e}")

if GATE and CONNECTED and os.path.exists(ABI_F):
    try:
        with open(ABI_F) as f:
            abi = json.load(f)
        contract = w3.eth.contract(address=Web3.to_checksum_address(GATE), abi=abi)
        logger.info(f"✓ TrustGate loaded: {GATE}")
    except Exception as e:
        logger.warning(f"⚠ Contract: {e}")

def phone_to_address(phone: str) -> str:
    h = hashlib.sha256(phone.encode()).hexdigest()
    return "0x" + h[-40:]

async def execute(sender_phone: str, receiver_phone: str,
                  usdc_wei: int, score: int) -> dict:
    if not (contract and ORACLE_ADDR and CONNECTED):
        fake = "0x" + hashlib.sha256(
            f"{sender_phone}{receiver_phone}{usdc_wei}{time.time()}".encode()
        ).hexdigest()
        logger.info(f"SIMULATED tx: {fake[:20]}...")
        return {
            "status":      "simulated",
            "tx_hash":     fake,
            "block":       0,
            "polygonscan": f"https://mumbai.polygonscan.com/tx/{fake}",
            "note":        "Deploy contract on Day 2 for real tx hashes"
        }

    sender_addr   = phone_to_address(sender_phone)
    receiver_addr = phone_to_address(receiver_phone)
    check_id      = w3.keccak(text=f"{sender_phone}{receiver_phone}{usdc_wei}")

    try:
        tx = contract.functions.execute(
            sender_addr, receiver_addr, usdc_wei, score, check_id
        ).build_transaction({
            "from":     ORACLE_ADDR,
            "nonce":    w3.eth.get_transaction_count(ORACLE_ADDR),
            "gas":      200000,
            "gasPrice": w3.to_wei("20", "gwei"),
            "chainId":  CHAIN
        })
        signed  = w3.eth.account.sign_transaction(tx, KEY)
        tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)
        h = tx_hash.hex()
        logger.info(f"✓ TX confirmed block #{receipt.blockNumber}")
        return {
            "status":      "confirmed",
            "tx_hash":     h,
            "block":       receipt.blockNumber,
            "gas_used":    receipt.gasUsed,
            "polygonscan": f"https://mumbai.polygonscan.com/tx/{h}"
        }
    except Exception as e:
        logger.error(f"Blockchain error: {e}")
        return {"status": "error", "error": str(e)}
PYEOF

echo "✓ trust-oracle/blockchain.py"

# ── trust-oracle/main.py ─────────────────────────────────
cat > trust-oracle/main.py << 'PYEOF'
"""
Ubuntu Pay — main.py
The Trust Oracle API server.

Run:  cd ~/UbuntuPay/trust-oracle
      uvicorn main:app --reload --port 8000

Test: http://localhost:8000/docs
"""
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from dotenv import load_dotenv
from loguru import logger

from database     import init_db, save_check, save_transfer, get_recent, get_stats
from nokia_client import check as nokia_check
from ai_agent     import score as ai_score
from currency     import kes_to_usdc, usdc_to_local, payout, get_rates
from blockchain   import execute as chain_execute

load_dotenv()

app = FastAPI(
    title="Ubuntu Pay — Trust Oracle",
    description="Nokia CAMARA APIs + Gemini AI = fraud prevention for African payments",
    version="1.0.0"
)

app.add_middleware(CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.on_event("startup")
async def startup():
    init_db()
    nokia  = "REAL" if os.getenv("NOKIA_API_KEY")  else "SIMULATION"
    gemini = "REAL" if os.getenv("GEMINI_API_KEY") else "UNAVAILABLE"
    logger.info(f"Ubuntu Pay Trust Oracle started")
    logger.info(f"Nokia: {nokia}  |  Gemini: {gemini}")

class CheckReq(BaseModel):
    sender:   str
    receiver: str
    amount:   float
    tx_type:  str = "cross_border"

class TransferReq(BaseModel):
    sender:      str
    receiver:    str
    kes:         float
    sender_name: Optional[str] = ""

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "nokia":  "real" if os.getenv("NOKIA_API_KEY")  else "simulation",
        "gemini": "real" if os.getenv("GEMINI_API_KEY") else "unavailable"
    }

@app.get("/stats")
async def stats():
    return await get_stats()

@app.get("/recent")
async def recent(limit: int = 20):
    return await get_recent(limit)

@app.get("/rates")
async def rates():
    return await get_rates()

@app.post("/check")
async def check(req: CheckReq):
    """
    1. Fire all 5 Nokia CAMARA APIs in parallel
    2. Feed signals to Gemini AI
    3. Return trust score + decision + reasoning
    4. Save to SQLite
    """
    logger.info(f"CHECK  {req.sender} → {req.receiver}  ${req.amount:.2f}")

    signals = await nokia_check(req.sender, req.receiver)
    logger.info(f"Nokia: {signals.ms}ms  SIM_SWAP={signals.sim_swapped}")

    result = await ai_score(signals, req.amount, req.tx_type)
    logger.info(f"Score: {result['score']}/100 — {result['decision']}")

    await save_check({
        "sender":           req.sender,
        "receiver":         req.receiver,
        "amount_usdc":      req.amount,
        "sim_swapped":      signals.sim_swapped,
        "device_changed":   signals.device_changed,
        "number_verified":  signals.number_verified,
        "kyc_score":        signals.kyc_score,
        "roaming":          signals.roaming,
        "trust_score":      result["score"],
        "decision":         result["decision"],
        "reasoning":        result["reasoning"],
        "ms":               signals.ms
    })

    return {
        "sender":   req.sender,
        "receiver": req.receiver,
        "amount":   req.amount,
        "signals": {
            "sim_swapped":     signals.sim_swapped,
            "rec_sim_swapped": signals.rec_sim_swapped,
            "device_changed":  signals.device_changed,
            "number_verified": signals.number_verified,
            "kyc_score":       round(signals.kyc_score, 3),
            "roaming":         signals.roaming,
            "country":         signals.country,
            "ms":              signals.ms
        },
        "score":    result["score"],
        "decision": result["decision"],
        "reasoning":result["reasoning"],
        "action": {
            "ALLOW":   "✓ Execute transfer on blockchain",
            "STEP_UP": "⚠ Request additional verification",
            "BLOCK":   "⛔ Reject — alert user"
        }.get(result["decision"])
    }

@app.post("/transfer")
async def transfer(req: TransferReq):
    """Full flow: KES → USDC → trust check → blockchain → MoMo payout"""
    logger.info(f"TRANSFER  {req.sender} → {req.receiver}  KES {req.kes}")

    usdc = await kes_to_usdc(req.kes)

    check_result = await check(CheckReq(
        sender=req.sender, receiver=req.receiver,
        amount=usdc, tx_type="cross_border"
    ))

    if check_result["decision"] != "ALLOW":
        return {
            "status":  "blocked",
            "reason":  check_result["reasoning"],
            "score":   check_result["score"]
        }

    chain = await chain_execute(
        sender_phone=req.sender,
        receiver_phone=req.receiver,
        usdc_wei=int(usdc * 10**6),
        score=check_result["score"]
    )

    ngn  = await usdc_to_local(usdc, "NGN")
    momo = await payout(req.receiver, usdc, "NGN")

    await save_transfer({
        "tx_hash":  chain.get("tx_hash"),
        "sender":   req.sender,
        "receiver": req.receiver,
        "kes":      req.kes,
        "usdc":     usdc,
        "score":    check_result["score"],
        "status":   chain.get("status")
    })

    return {
        "status":       chain.get("status"),
        "tx_hash":      chain.get("tx_hash"),
        "polygonscan":  chain.get("polygonscan"),
        "sender":       req.sender,
        "receiver":     req.receiver,
        "kes_sent":     req.kes,
        "usdc_settled": usdc,
        "ngn_received": ngn,
        "score":        check_result["score"],
        "reasoning":    check_result["reasoning"],
        "momo":         momo
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

echo "✓ trust-oracle/main.py"

# ── ussd-gateway/ussd.py ─────────────────────────────────
cat > ussd-gateway/ussd.py << 'PYEOF'
"""
Ubuntu Pay — ussd.py
USSD gateway for *384#

Run:  cd ~/UbuntuPay/ussd-gateway
      uvicorn ussd:app --reload --port 8001

Test: http://localhost:8001/simulate
"""
import httpx
import os
from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Ubuntu Pay USSD Gateway")
app.add_middleware(CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

ORACLE   = os.getenv("TRUST_ORACLE_URL", "http://localhost:8000")
sessions = {}

@app.post("/ussd")
async def ussd(
    sessionId:   str = Form(...),
    serviceCode: str = Form(...),
    phoneNumber: str = Form(...),
    text:        str = Form("")
):
    parts = text.split("*") if text else []
    n     = len(parts)
    first = parts[0] if n > 0 else ""

    if n == 0:
        sessions[sessionId] = {"phone": phoneNumber}
        return ("CON Ubuntu Pay *384#\n"
                "1. Send Money\n"
                "2. My Balance\n"
                "3. Save Money\n"
                "0. Lock Wallet")

    if first == "1":
        if n == 1:
            return "CON Enter recipient phone number:"
        if n == 2:
            rec = parts[1]
            if rec.startswith("07") or rec.startswith("01"):
                rec = "+254" + rec[1:]
            elif not rec.startswith("+"):
                rec = "+" + rec
            sessions[sessionId]["receiver"] = rec
            return f"CON Send to {parts[1]}\nEnter amount (KES):"
        if n == 3:
            try:
                amt = float(parts[2])
            except ValueError:
                return "END Invalid amount. Please try again."
            sessions[sessionId]["amount"] = amt
            rec = sessions[sessionId].get("receiver", parts[1])
            return (f"CON Confirm transfer\n"
                    f"To:     {rec}\n"
                    f"Amount: KES {amt:.0f}\n"
                    f"Fee:    KES {amt*0.003:.0f} (0.3%)\n"
                    f"1. Confirm\n2. Cancel")
        if n == 4:
            if parts[3] != "1":
                return "END Cancelled."
            sess = sessions.get(sessionId, {})
            rec  = sess.get("receiver", "")
            amt  = sess.get("amount", 0)
            if not rec or not amt:
                return "END Session expired. Dial *384# to retry."
            try:
                async with httpx.AsyncClient(timeout=30.0) as c:
                    r = await c.post(f"{ORACLE}/transfer",
                                     json={"sender": phoneNumber, "receiver": rec, "kes": amt})
                d = r.json()
                if d.get("status") == "blocked":
                    return (f"END BLOCKED\n"
                            f"Trust score: {d.get('score',0)}/100\n"
                            f"Your account is protected.")
                tx = str(d.get("tx_hash",""))[:14]
                return (f"END Sent KES {amt:.0f}\n"
                        f"To: {rec}\n"
                        f"Score: {d.get('score',0)}/100\n"
                        f"USDC: {d.get('usdc_settled',0):.2f}\n"
                        f"Ref: {tx}...")
            except Exception as e:
                return f"END Service unavailable.\nTry again. ({str(e)[:40]})"

    elif first == "2":
        return ("END Ubuntu Pay Balance\n"
                "Available: KES 8,000\n"
                "Savings:   KES 3,000 (3% APY)\n"
                "Dial *384*1# to send money")

    elif first == "3":
        if n == 1:
            return "CON Ubuntu Save — 3% APY\nEnter amount to save (KES):"
        if n == 2:
            return (f"CON Save KES {parts[1]}\n"
                    f"Earn 3% APY — withdraw anytime\n"
                    f"1. Confirm\n2. Cancel")
        if n == 3 and parts[2] == "1":
            return (f"END Saved KES {parts[1]}\n"
                    f"Now earning 3% APY\n"
                    f"Powered by Aave DeFi")
        return "END Cancelled."

    elif first == "0":
        if n == 1:
            return "CON Enter emergency PIN to lock wallet:"
        return ("END Wallet locked.\n"
                "All outgoing transfers blocked.\n"
                "Dial *384*0# to unlock.")

    return "END Invalid option."

@app.get("/simulate")
async def simulate(phone: str = "+254712000001", text: str = ""):
    return await ussd(
        sessionId="TEST-" + phone[-4:],
        serviceCode="*384#",
        phoneNumber=phone,
        text=text
    )
PYEOF

echo "✓ ussd-gateway/ussd.py"

# ── scripts/gen_wallet.py ────────────────────────────────
cat > scripts/gen_wallet.py << 'PYEOF'
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
PYEOF

echo "✓ scripts/gen_wallet.py"

# ── smart-contracts/TrustGate.sol ────────────────────────
cat > smart-contracts/TrustGate.sol << 'SOLEOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TrustGate {
    address public owner;
    address public oracle;
    IERC20  public usdc;
    uint8   public minScore = 70;

    uint256 public totalTx;
    uint256 public totalBlocked;
    uint256 public totalVolume;

    event Executed(address indexed sender, address indexed receiver,
                   uint256 amount, uint8 score, bytes32 checkId);
    event Blocked(address indexed sender, uint8 score, string reason);

    modifier onlyOracle() { require(msg.sender == oracle, "Not oracle"); _; }
    modifier onlyOwner()  { require(msg.sender == owner,  "Not owner");  _; }

    constructor(address _oracle, address _usdc) {
        owner  = msg.sender;
        oracle = _oracle;
        usdc   = IERC20(_usdc);
    }

    function execute(address sender, address receiver,
                     uint256 amount, uint8 score, bytes32 checkId)
    external onlyOracle {
        require(score >= minScore, "Trust score too low");
        require(amount > 0, "Amount must be positive");
        require(usdc.transferFrom(sender, receiver, amount), "USDC transfer failed");
        totalTx++;
        totalVolume += amount;
        emit Executed(sender, receiver, amount, score, checkId);
    }

    function logBlock(address sender, uint8 score, string calldata reason)
    external onlyOracle {
        totalBlocked++;
        emit Blocked(sender, score, reason);
    }

    function getStats() external view returns (uint256, uint256, uint256) {
        return (totalTx, totalBlocked, totalVolume);
    }

    function setOracle(address _oracle) external onlyOwner { oracle = _oracle; }
    function setMinScore(uint8 _score)  external onlyOwner {
        require(_score <= 100); minScore = _score;
    }
}
SOLEOF

echo "✓ smart-contracts/TrustGate.sol"

# ── smart-contracts/hardhat.config.js ───────────────────
cat > smart-contracts/hardhat.config.js << 'JSEOF'
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: "../.env" });

module.exports = {
  solidity: "0.8.20",
  networks: {
    mumbai: {
      url:      process.env.POLYGON_RPC_URL || "https://rpc-mumbai.maticvigil.com",
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : [],
      chainId:  80001
    }
  }
};
JSEOF

echo "✓ smart-contracts/hardhat.config.js"

# ── smart-contracts/deploy.js ────────────────────────────
cat > smart-contracts/deploy.js << 'JSEOF'
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("\n════════════════════════════════════════");
  console.log("Ubuntu Pay — TrustGate Deployment");
  console.log(`Network:  ${hre.network.name}`);
  console.log(`Deployer: ${deployer.address}`);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`Balance:  ${hre.ethers.formatEther(balance)} MATIC\n`);

  if (balance < hre.ethers.parseEther("0.01")) {
    console.error("❌ Need more MATIC — get free at: https://faucet.polygon.technology");
    process.exit(1);
  }

  const USDC_MUMBAI = "0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97";
  const TrustGate   = await hre.ethers.getContractFactory("TrustGate");
  const gate        = await TrustGate.deploy(deployer.address, USDC_MUMBAI);
  await gate.waitForDeployment();
  const addr = await gate.getAddress();

  console.log("════════════════════════════════════════");
  console.log(`✓ Deployed: ${addr}`);
  console.log(`  https://mumbai.polygonscan.com/address/${addr}`);
  console.log(`\n  Add to .env:\n  TRUST_GATE_ADDRESS=${addr}`);
  console.log("════════════════════════════════════════\n");

  const fs  = require("fs");
  const art = await hre.artifacts.readArtifact("TrustGate");
  fs.writeFileSync("../trust-oracle/TrustGate.abi.json", JSON.stringify(art.abi, null, 2));
  console.log("✓ ABI saved to trust-oracle/TrustGate.abi.json");
}

main().catch(e => { console.error(e); process.exit(1); });
JSEOF

echo "✓ smart-contracts/deploy.js"

echo ""
echo "════════════════════════════════════════"
echo "✓ All files created successfully!"
echo ""
echo "Next step:"
echo "  cd trust-oracle"
echo "  uvicorn main:app --reload --port 8000"
echo "════════════════════════════════════════"
