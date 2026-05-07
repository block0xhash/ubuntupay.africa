#!/bin/bash
# 🚀 Ubuntu Pay: Trust Oracle Startup
# Purpose: Starts the central intelligence engine (Nokia + AI + Blockchain)

echo "Starting Ubuntu Pay Trust Oracle..."
# We use --reload so changes to logic are updated live during the demo
uvicorn main:app --reload --host 0.0.0.0 --port 8000
