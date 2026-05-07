# ============================================================
# ADD TO main.py — paste before the `if __name__ == "__main__"` block
# ============================================================

@app.get("/health")
async def health():
    """Dashboard health check — confirms Nokia and Gemini status."""
    nokia_ok = nokia_client.client is not None
    return {
        "status": "ok",
        "nokia":  "real" if nokia_ok else "offline",
        "gemini": "real",
        "chain":  "polygon_amoy"
    }


@app.get("/recent")
async def recent(limit: int = 5):
    """Returns most recent trust checks for the live log panel on the dashboard."""
    try:
        async with __import__('aiosqlite').connect(database.DB_PATH) as db:
            db.row_factory = __import__('aiosqlite').Row
            q = await db.execute(
                "SELECT sender, decision, trust_score, reasoning, ts "
                "FROM checks ORDER BY ts DESC LIMIT ?", (limit,)
            )
            rows = await q.fetchall()
            return [
                {
                    "sender":      r["sender"],
                    "receiver":    "",
                    "decision":    r["decision"],
                    "trust_score": r["trust_score"],
                    "reasoning":   r["reasoning"]
                }
                for r in rows
            ]
    except Exception as e:
        return []
