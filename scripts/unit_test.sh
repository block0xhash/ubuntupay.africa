
# 1. Check current balances
curl http://localhost:8000/balance/phone/%2B99999991001
curl http://localhost:8000/balance/phone/%2B99999991002
curl http://localhost:8000/agent/balance

# 2. Deposit into Joseph
curl -X POST http://localhost:8000/deposit \
  -H "Content-Type: application/json" \
  -d '{"phone":"+99999991001","kes":1000,"agent_lat":-1.286389,"agent_long":36.817223}'

# 3. Transfer to John
curl -X POST http://localhost:8000/transfer \
  -H "Content-Type: application/json" \
  -d '{"sender":"+99999991001","receiver":"+99999991002","name":"John","kes":500,"pin":"1234"}'

# 4. Wait 17 seconds then check both
curl http://localhost:8000/balance/phone/%2B99999991001
curl http://localhost:8000/balance/phone/%2B99999991002
