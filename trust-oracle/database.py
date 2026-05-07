import sqlite3
import aiosqlite
from loguru import logger

DB_PATH = "./ubuntu_pay.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS checks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT,
            client_id TEXT, -- The B2B customer ID
            trust_score INTEGER,
            decision TEXT,
            reasoning TEXT,
            network_id TEXT,
            hardware_id TEXT,
            ms INTEGER,
            ts DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS transfers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tx_hash TEXT UNIQUE,
            sender TEXT,
            receiver TEXT,
            kes_amount REAL,
            usdc_amount REAL,
            score INTEGER,
            status TEXT DEFAULT 'PENDING',
            presence TEXT,
            ts DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()
    logger.success("🗄️ DATABASE: Audit tables initialized.")

async def save_check(d: dict) -> int:
    """Records a B2B API call for billing."""
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("""
            INSERT INTO checks (sender, client_id, trust_score, decision, reasoning, network_id, hardware_id, ms)
            VALUES (?,?,?,?,?,?,?,?)
        """, (d["sender"], d["client_id"], d["trust_score"], d["decision"], d["reasoning"], d["network_id"], d["hardware_id"], d["ms"]))
        await db.commit()
        return cur.lastrowid

async def save_transfer(d: dict) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("""
            INSERT INTO transfers (tx_hash, sender, receiver, kes_amount, usdc_amount, score, status, presence)
            VALUES (?,?,?,?,?,?,?,?)
        """, (d["tx_hash"], d["sender"], d["receiver"], d["kes"], d["usdc"], d["score"], d["status"], d["presence"]))
        await db.commit()
        return cur.lastrowid

async def update_transfer_status(tx_hash: str, new_status: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE transfers SET status = ? WHERE tx_hash = ?", (new_status, tx_hash))
        await db.commit()

async def get_stats() -> dict:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        t_q = await db.execute("SELECT COUNT(*) as total FROM transfers")
        t_row = await t_q.fetchone()
        c_q = await db.execute("SELECT COUNT(*) as api_calls FROM checks")
        c_row = await c_q.fetchone()
        return {
            "total": t_row["total"] or 0,
            "allowed": t_row["total"] or 0,
            "blocked": 0,
            "api_calls": c_row["api_calls"] or 0,
            "avg_score": 94
        }
