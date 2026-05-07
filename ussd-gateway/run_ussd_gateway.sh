#!/bin/bash
# 🚀 Ubuntu Pay USSD Startup
# We set PYTHONPATH to the current directory to resolve symlinks
export PYTHONPATH=$PYTHONPATH:.
uvicorn ussd:app --reload --port 8001
