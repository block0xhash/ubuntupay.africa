**UBUNTU PAY — AFRICA IGNITE 2026 SUBMISSION**

_Website: https://ubuntupay.africa/
Demo: https://ubuntupay.africa/demo-ussd.html_
_Smart Contract: https://amoy.polygonscan.com/address/0xaa5D997CaD5C528DCf9AC1D07d8DD5154C3D66D5#code_

S**ection 1: Problem Statement**

Despite the rapid growth of digital finance, an estimated 850 million people in Africa remain financially excluded. Existing digital banking and blockchain solutions fail for three primary reasons. First, the Smartphone and Data Barrier creates a gap where most fintech apps require high-end devices and expensive data plans inaccessible to the rural majority. Second, the Identity Gap persists because millions lack the formal documentation required for traditional Tier-1 KYC. Ubuntu Pay bridges this by utilizing the existing identity registered with the cellular network, turning the SIM card's legal registration into a hardware-verified digital ID. Third, the Trust and Complexity barrier prevents adoption because modern blockchain wallets require the management of 12-word seed phrases, where losing a backup means losing a lifetime of savings.

**Section 2: Project Objective**

The objective of Ubuntu Pay is to turn the cellular network into the bank. By leveraging existing cellular infrastructure and Nokia’s Network-as-Code (NaC) platform, we turn a basic SIM card into a secure, hardware-verified bank account. Our goal is to provide institutional-grade P2P transfers and remittances to any individual with a mobile signal, regardless of their phone's hardware capabilities.

**Section 3: Methodology and Core Innovation**

Ubuntu Pay utilizes a multi-layered trust architecture to solve the exclusion and transfer problem. For the Identity Layer, we utilize the identity already registered with the cellular network, querying Nokia CAMARA APIs to verify the physical SIM card's reputation (SIM age, swap history) as a hardware-based KYC signal. For the Intelligence Layer, Gemini AI acts as a "Trust Oracle," processing real-time network signals to generate a security score, blocking 94% of account takeovers before a transaction starts. The Execution Layer uses the TrustGate.sol smart contract to execute Peer-to-Peer transfers on the Polygon blockchain using Circle’s USDC for value stability. Finally, the Access Layer solves the "lost seed phrase" problem by using Argon2id to bind the user's secret PIN to their unique SIM metadata. This transforms the SIM into a Hardware Security Module, where the wallet is derived on-the-fly and cannot be accessed from another device.

**Section 4: Scope of Proposed Solution**

The current scope focuses on the Nairobi-Lagos Remittance Corridor. This includes instant P2P fund transfers with sub-11 second settlement and a safety net protocol that allows for administrative reversals in verified fraud cases, mirroring the safety of legacy banking. To ensure accessibility, a USSD gateway (*384#) allows users to initiate requests without a smartphone or data plan. Furthermore, the system offers Trust-as-a-Service, providing an API for other fintechs and banks to use our Nokia-powered scoring engine for their own validation needs.

**Section 5: Technical Implementation Details**

The system combines legacy cellular protocols with cutting-edge decentralized finance. The Settlement Rail uses Polygon Amoy for low-cost transactions, while the currency is Circle USDC, ensuring value is backed 1:1 by U.S. Dollars. The Trust Layer integrates six Nokia CAMARA APIs to verify the physical presence and reputation of the SIM card. Key Derivation uses Argon2id to bind the user's PIN to their specific hardware, removing the need for seed phrases. The Risk Engine is powered by Gemini AI for fraud reasoning and trust scoring. The User Interface is a USSD Gateway, ensuring the solution works on basic feature phones via standard shortcodes.

**Section 6: Conclusion**

Ubuntu Pay is a reimagining of trust. By turning the cellular network into a cryptographic witness, we remove the final barriers to financial sovereignty for the next billion users. We provide the speed of a global blockchain and the stability of the U.S. Dollar through the simplicity of a basic mobile signal.




<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p><strong>Ubuntu Pay</strong></p>
<p><strong>Installation Guide</strong></p>
<p>Complete setup: environment · wallets · smart contract · Trust Oracle
· USSD gateway</p>
<p>Africa Ignite 2026 · Theme 6: Open Innovation · Shortlisted</p></td>
</tr>
</tbody>
</table>

|  |  |  |  |
|-----------------|-----------------|-----------------|---------------------|
| **Stack** | **Contract** | **Network** | **APIs** |
| Python 3.13 · FastAPI | TrustGate.sol · Solidity 0.8.20 | Polygon Amoy (testnet) | Nokia CAMARA · Gemini 3.1 · Yellow Card |

# **1. Project Structure**

The structure below is what you get
after running setup.sh or cloning the repository.

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>~/UbuntuPay/</p>
<p>│</p>
<p>├── .env # All secrets — never commit this</p>
<p>├── .env.example # Template — safe to commit</p>
<p>├── venv/ # Python virtual environment</p>
<p>│</p>
<p>├── trust-oracle/ # FastAPI backend :8000</p>
<p>│ ├── main.py # API server — entry point</p>
<p>│ ├── nokia_client.py # 6 Nokia CAMARA APIs</p>
<p>│ ├── ai_agent.py # Gemini 3.1 scoring</p>
<p>│ ├── blockchain.py # Polygon + TrustGate.sol</p>
<p>│ ├── currency.py # Yellow Card FX rates</p>
<p>│ ├── database.py # SQLite audit trail</p>
<p>│ ├── regional_config.py # Per-country fee rules</p>
<p>│ ├── TrustGate.abi.json # Generated by deploy.js</p>
<p>│ └── ubuntu_pay.db # SQLite database (auto-created)</p>
<p>│</p>
<p>├── ussd-gateway/ # USSD gateway :8001</p>
<p>│ ├── ussd.py # *384# handler (Africa's Talking format)</p>
<p>│ └── regional_config.py # Country routing</p>
<p>│</p>
<p>├── smart-contracts/ # Solidity + deployment</p>
<p>│ ├── src/</p>
<p>│ │ └── TrustGate.sol # Deployed contract</p>
<p>│ ├── script/</p>
<p>│ │ └── Deploy.s.sol # Foundry deploy script</p>
<p>│ ├── deploy.js # ethers.js deploy (alternative)</p>
<p>│ ├── foundry.toml # Foundry config</p>
<p>│ ├── hardhat.config.js # Hardhat config (alternative)</p>
<p>│ └── package.json</p>
<p>│</p>
<p>├── scripts/</p>
<p>│ ├── gen_wallet.py # Generates deployer + oracle wallets</p>
<p>│ └── setup.sh # First-time project setup</p>
<p>│</p>
<p>└── dashboard/ # Static website (serve with Python)</p>
<p>├── index.html # Landing page</p>
<p>├── demo-ussd.html # Nokia USSD live demo</p>
<p>├── backend.html # Developer console</p>
<p>├── deck.html # Pitch deck</p>
<p>└── whitepaper.html # Technical whitepaper</p></td>
</tr>
</tbody>
</table>

*Figure 1. Complete project folder structure*

# **2. Prerequisites**

## **2.1 System Requirements**

|  |  |  |
|------------------|------------------|---------------------------------|
| **Tool** | **Version** | **Purpose** |
| Python | 3.11 or 3.13 | Trust Oracle + USSD Gateway |
| Node.js | 18 LTS or 20 LTS | Contract deployment (ethers.js) |
| Git | Any recent | Clone repository |
| Foundry (optional) | Latest | Preferred contract compiler — forge + cast |
| Python http.server | Built-in | Serve the dashboard HTML files |

## **2.2 API Keys You Need**

Obtain these before running anything. All are free for hackathon/testnet
use.

|  |  |  |
|------------------|-----------------------|-----------------------------|
| **Service** | **Get It At** | **Used For** |
| Nokia Network as Code | networkascode.nokia.io | 6 CAMARA APIs — SIM swap, device, KYC, roaming, location, number verify |
| Google Gemini | aistudio.google.com | AI trust scoring — model: gemini-3.1-flash-lite-preview |
| Yellow Card | yellowcard.io/developers | KES→USDC and USDC→NGN FX rates and payouts (sandbox works fine) |
| Polygonscan (Etherscan) | amoy.polygonscan.com | Contract verification after deployment |

<table style="width:96%;">
<colgroup>
<col style="width: 2%" />
<col style="width: 94%" />
</colgroup>
<tbody>
<tr>
<td></td>
<td><p><strong>Nokia key optional for demo</strong></p>
<p>Without NOKIA_API_KEY the system runs in simulation mode. All 6 APIs
return realistic fake data. The full end-to-end demo works perfectly —
Nokia signals, Gemini scoring, Polygon settlement. Set the real key to
see live Safaricom network data.</p></td>
</tr>
</tbody>
</table>

# **3. Python Environment**

## **3.1 Create Virtual Environment**

Always use a virtual environment. This keeps dependencies isolated and
avoids conflicts with system Python.

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p># Create the project folder and virtual environment</p>
<p>mkdir -p ~/UbuntuPay &amp;&amp; cd ~/UbuntuPay</p>
<p>python3 -m venv venv</p>
<p># Activate — do this every terminal session</p>
<p>source venv/bin/activate</p>
<p># You should see (venv) at the start of your prompt</p>
<p># (venv) user@machine:~/UbuntuPay$</p></td>
</tr>
</tbody>
</table>

## **3.2 Install Python Dependencies**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>pip install --upgrade pip</p>
<p>pip install fastapi uvicorn[standard] python-dotenv</p>
<p>pip install network-as-code # Nokia CAMARA SDK</p>
<p>pip install google-generativeai # Gemini 3.1</p>
<p>pip install web3 eth-account # Polygon / Argon2id wallets</p>
<p>pip install argon2-cffi # Wallet key derivation</p>
<p>pip install aiosqlite httpx loguru</p></td>
</tr>
</tbody>
</table>

*Run from ~/UbuntuPay with venv activated*

<table style="width:96%;">
<colgroup>
<col style="width: 2%" />
<col style="width: 94%" />
</colgroup>
<tbody>
<tr>
<td></td>
<td><p><strong>Verify installation</strong></p>
<p>Run: python3 -c "import fastapi, network_as_code,
google.generativeai, web3; print('All dependencies ready')" — if no
errors appear, you are good to go.</p></td>
</tr>
</tbody>
</table>

# **4. Generate Wallets**

Ubuntu Pay uses two Polygon wallets: a Deployer wallet (deploys
TrustGate.sol) and an Oracle wallet (signs on-chain transactions).
Generate them with the included script — never use real funds on testnet
wallets.

## **4.1 Run the Generator**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay</p>
<p>source venv/bin/activate</p>
<p>python3 scripts/gen_wallet.py</p></td>
</tr>
</tbody>
</table>

The script outputs:

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>════════════════════════════════════════</p>
<p>Ubuntu Pay — Wallet Generator</p>
<p>⚠ Save these keys. Never share them.</p>
<p>════════════════════════════════════════</p>
<p>DEPLOYER</p>
<p>Address: 0x1525....</p>
<p>Key: 0xfe4fdb38...</p>
<p>ORACLE</p>
<p>Address: 0xee861eD8dBE...</p>
<p>Key: 0x2004abc3d64...</p>
<p>Add to .env:</p>
<p>DEPLOYER_PRIVATE_KEY=0xfe4fdb...</p>
<p>ORACLE_PRIVATE_KEY=0x2004ab...</p>
<p>Fund DEPLOYER at: https://faucet.polygon.technology</p>
<p>Paste: 0x152589D97EF3E32e944ff7ea303eB9D656949EFe</p>
<p>════════════════════════════════════════</p></td>
</tr>
</tbody>
</table>

*Example output from gen_wallet.py — your addresses will differ*

## **4.2 Fund the Deployer Wallet**

The Deployer wallet needs test MATIC to pay gas for contract deployment.
The Oracle wallet needs test USDC to process transfers.

|                |                  |                           |
|----------------|------------------|---------------------------|
| **Wallet**     | **Needs**        | **Faucet**                |
| Deployer       | 0.1 MATIC (free) | faucet.polygon.technology |
| Agent / Oracle | Test USDC (free) | faucet.circle.com         |

<table style="width:96%;">
<colgroup>
<col style="width: 2%" />
<col style="width: 94%" />
</colgroup>
<tbody>
<tr>
<td></td>
<td><p><strong>⚠ Never commit private keys</strong></p>
<p>The .gitignore already excludes .env. Double-check before any git
push. The keys in this document are examples only — regenerate your
own.</p></td>
</tr>
</tbody>
</table>

# **5. Environment Variables**

Copy .env.example to .env and fill in every value. The file lives in the
project root (~/UbuntuPay/.env) and is loaded by all Python modules via
python-dotenv.

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cp .env.example .env</p>
<p>nano .env # or code .env, vim .env, etc.</p></td>
</tr>
</tbody>
</table>

## **5.1 Complete .env Reference**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p># ══════════════════════════════════════════════════════</p>
<p># NOKIA NETWORK AS CODE</p>
<p># Get free key: networkascode.nokia.io/auth/sign-up</p>
<p># Without this key the system runs in simulation mode</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export NOKIA_API_KEY=your_nokia_api_key_here</p>
<p># ══════════════════════════════════════════════════════</p>
<p># GOOGLE GEMINI 3.1</p>
<p># Get free key: aistudio.google.com → Get API Key</p>
<p># Model used: gemini-3.1-flash-lite-preview</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export GEMINI_API_KEY=your_gemini_api_key_here</p>
<p># ══════════════════════════════════════════════════════</p>
<p># POLYGON AMOY TESTNET</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export POLYGON_RPC_URL=https://rpc-amoy.polygon.technology</p>
<p>export POLYGON_CHAIN_ID=80002</p>
<p># ══════════════════════════════════════════════════════</p>
<p># WALLET KEYS (from gen_wallet.py output)</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export DEPLOYER_PRIVATE_KEY=0x_your_deployer_key</p>
<p>export ORACLE_PRIVATE_KEY=0x_your_oracle_key</p>
<p>export DEPLOYER_ADDRESS=0x_your_deployer_address</p>
<p>export ORACLE_ADDRESS=0x_your_oracle_address</p>
<p>export AGENT_ADDRESS=0x_your_agent_address # same as deployer for
testnet</p>
<p># ══════════════════════════════════════════════════════</p>
<p># SMART CONTRACT (set AFTER deployment)</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export TRUST_GATE_ADDRESS=0x_deployed_contract_address</p>
<p>export
USDC_TOKEN_ADDRESS=0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582</p>
<p># ══════════════════════════════════════════════════════</p>
<p># YELLOW CARD (FX rates + MoMo payouts)</p>
<p># Sandbox key works with no real money</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export YELLOW_CARD_API_KEY=your_yc_key_or_leave_empty</p>
<p>export YELLOW_CARD_BASE_URL=https://api.sandbox.yellowcard.io</p>
<p># ══════════════════════════════════════════════════════</p>
<p># POLYGONSCAN (contract verification)</p>
<p># Get free key: amoy.polygonscan.com → API Keys</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export ETHERSCAN_KEY=your_polygonscan_api_key</p>
<p># ══════════════════════════════════════════════════════</p>
<p># SYSTEM SETTINGS</p>
<p># ══════════════════════════════════════════════════════</p>
<p>export DATABASE_PATH=./ubuntu_pay.db # SQLite file location</p>
<p>export MIN_TRUST_SCORE=70 # Minimum score to ALLOW a transfer</p>
<p>export CROSS_BORDER_FEE=0.003 # 0.3% fee on every transfer</p>
<p>export FX_SPREAD=0.001 # 0.1% FX spread</p></td>
</tr>
</tbody>
</table>

*Complete .env file — copy to ~/UbuntuPay/.env*

## **5.2 Environment Variables Quick Reference**

|  |  |  |
|---------------------|-----------|--------------------------------------|
| **Variable** | **Required** | **Description** |
| NOKIA_API_KEY | No\* | Nokia CAMARA API key. Without it: simulation mode — demo still works. |
| GEMINI_API_KEY | Yes | Google AI Studio key. Used for trust scoring with gemini-3.1-flash-lite-preview. |
| POLYGON_RPC_URL | Yes | Amoy testnet RPC. Default: https://rpc-amoy.polygon.technology |
| POLYGON_CHAIN_ID | Yes | Must be 80002 for Polygon Amoy. |
| DEPLOYER_PRIVATE_KEY | Yes | Ethereum private key for contract deployer wallet. From gen_wallet.py. |
| ORACLE_PRIVATE_KEY | Yes | Ethereum private key for oracle signer wallet. From gen_wallet.py. |
| ORACLE_ADDRESS | Yes | Public address of oracle wallet. Passed to TrustGate constructor. |
| TRUST_GATE_ADDRESS | Yes | Deployed contract address. Set AFTER running deploy.js. |
| USDC_TOKEN_ADDRESS | Yes | Test USDC on Amoy: 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582 |
| YELLOW_CARD_API_KEY | No\* | Yellow Card sandbox key. Without it: hardcoded FX rates are used. |
| ETHERSCAN_KEY | No\* | Polygonscan API key for contract verification only. |
| DATABASE_PATH | No | SQLite file path. Default: ./ubuntu_pay.db (created automatically). |
| MIN_TRUST_SCORE | No | Minimum Nokia+Gemini score to allow transfer. Default: 70. |
| CROSS_BORDER_FEE | No | Fee applied to every transfer. Default: 0.003 (0.3%). |
| FX_SPREAD | No | FX spread on KES→USDC conversion. Default: 0.001 (0.1%). |

\* Simulation mode runs automatically when optional keys are absent.

# **6. Smart Contract — TrustGate.sol**

TrustGate.sol is the on-chain settlement engine deployed on Polygon
Amoy. It holds USDC balances, enforces Nokia trust scores, and provides
a 15-second escrow reversal window. It is already deployed and verified
— you only need to redeploy if you want your own instance.

<table style="width:96%;">
<colgroup>
<col style="width: 2%" />
<col style="width: 94%" />
</colgroup>
<tbody>
<tr>
<td></td>
<td><p><strong>Already deployed</strong></p>
<p>Contract: 0x1373A4c5779536A7265a5a4EC70Bc288A208581A · Polygon Amoy ·
chainId 80002. Verified source:
amoy.polygonscan.com/address/0x1373A4c5779536A7265a5a4EC70Bc288A208581A#code.
You can skip Section 6.2–6.4 and just use this address in your
.env.</p></td>
</tr>
</tbody>
</table>

## **6.1 Key Contract Functions**

|  |  |  |
|--------------------|----------|----------------------------------------|
| **Function** | **Caller** | **Description** |
| depositFor() | Agent | Cash-in: moves USDC from agent wallet to user's Nokia-derived vault balance. |
| execute() | Oracle | Escrow: requires Nokia+Gemini score ≥ minScore. Emits EscrowStarted. |
| finalizeTransfer() | Oracle | Releases USDC after 15-second grace period. Revenue fee sent to owner. |
| reverseTransfer() | Oracle | Returns principal + fee within 15s grace period. Triggered by \*384\*5#. |
| migrateIdentity() | Oracle | Lost device recovery: moves balance from old Argon2id address to new one. |
| setWalletLock() | Oracle | Emergency freeze via \*384\*0# or automatic Nokia SIM swap detection. |
| balances(address) | Anyone | Returns USDC balance. Called by USSD \*384\*2# vault check in real time. |

## **6.2 Compile with Foundry (Preferred)**

Foundry is faster, more reliable, and produces smaller bytecode than
Hardhat. Install it once:

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p># Install Foundry (one-time)</p>
<p>curl -L https://foundry.paradigm.xyz | bash</p>
<p>source ~/.bashrc # or open a new terminal</p>
<p>foundryup # installs forge, cast, anvil</p>
<p># Verify installation</p>
<p>forge --version # should show: forge 0.2.x</p></td>
</tr>
</tbody>
</table>

Compile the contract:

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/smart-contracts</p>
<p># Install OpenZeppelin and other deps</p>
<p>forge install</p>
<p># Compile</p>
<p>forge build</p>
<p># Expected output:</p>
<p># [⠒] Compiling...</p>
<p># [⠢] Compiling 1 files with Solc 0.8.20</p>
<p># [⠆] Solc 0.8.20 finished in 1.23s</p>
<p># Compiler run successful!</p>
<p># Artifact written to: out/TrustGate.sol/TrustGate.json</p></td>
</tr>
</tbody>
</table>

## **6.3 Compile with Hardhat (Alternative)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/smart-contracts</p>
<p># Install Node dependencies</p>
<p>npm install</p>
<p># Compile</p>
<p>npx hardhat compile</p>
<p># Expected output:</p>
<p># Compiled 1 Solidity file successfully</p>
<p># Artifact: artifacts/contracts/TrustGate.sol/TrustGate.json</p></td>
</tr>
</tbody>
</table>

## **6.4 Deploy to Polygon Amoy**

Fund the deployer wallet with test MATIC first
(faucet.polygon.technology). Then:

### **Option A — Foundry (recommended)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/smart-contracts</p>
<p># Load environment variables</p>
<p>source ../.env</p>
<p># Deploy</p>
<p>forge script script/Deploy.s.sol \</p>
<p>--rpc-url $POLYGON_RPC_URL \</p>
<p>--private-key $DEPLOYER_PRIVATE_KEY \</p>
<p>--broadcast \</p>
<p>--verify \</p>
<p>--etherscan-api-key $ETHERSCAN_KEY</p>
<p># Copy the deployed address and add to .env:</p>
<p># export TRUST_GATE_ADDRESS=0x_new_address</p></td>
</tr>
</tbody>
</table>

### **Option B — ethers.js deploy.js**

Use deploy.js if you do not want to install Foundry. You need the ABI
and bytecode first — export them from Remix IDE or from the Hardhat
compile output.

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/smart-contracts</p>
<p># Copy ABI and bytecode from Hardhat artifacts</p>
<p>cp artifacts/contracts/TrustGate.sol/TrustGate.json
../trust-oracle/TrustGate.abi.json</p>
<p># Install ethers.js</p>
<p>npm install ethers dotenv</p>
<p># Edit deploy.js — set oracleAddress to your ORACLE_ADDRESS</p>
<p># Then deploy:</p>
<p>node deploy.js</p>
<p># Output:</p>
<p># ✅ TrustGate Deployed Successfully!</p>
<p># Contract Address: 0x...</p>
<p># 👉 Copy the Contract Address into .env as
TRUST_GATE_ADDRESS</p></td>
</tr>
</tbody>
</table>

## **6.5 Copy ABI to Trust Oracle**

The Trust Oracle (main.py) needs the contract ABI to call TrustGate
functions. After deployment:

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p># If using Foundry:</p>
<p>cp smart-contracts/out/TrustGate.sol/TrustGate.json
trust-oracle/TrustGate.abi.json</p>
<p># If using Hardhat:</p>
<p>cp smart-contracts/artifacts/contracts/TrustGate.sol/TrustGate.json
trust-oracle/TrustGate.abi.json</p>
<p># Verify the file exists:</p>
<p>ls -lh trust-oracle/TrustGate.abi.json</p>
<p># -rw-r--r-- 1 user 8.2K TrustGate.abi.json</p></td>
</tr>
</tbody>
</table>

# **7. Running the Servers**

Ubuntu Pay has three processes. Run each in a separate terminal tab.

## **Terminal 1 — Trust Oracle (port 8000)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/trust-oracle</p>
<p>source ../venv/bin/activate</p>
<p>source ../.env</p>
<p>uvicorn main:app --host 0.0.0.0 --port 8000 --reload</p>
<p># Expected startup output:</p>
<p># ✓ Database ready: ./ubuntu_pay.db</p>
<p># ✓ Nokia Network as Code — REAL API connected (or SIMULATION
mode)</p>
<p># ✓ Polygon Amoy connected (block #12345678)</p>
<p># ✓ Oracle wallet: 0xee861eD8dBE89952...</p>
<p># ✓ TrustGate loaded: 0x1373A4c5779536...</p>
<p># INFO: Uvicorn running on http://0.0.0.0:8000</p>
<p># Test it:</p>
<p>curl http://localhost:8000/health</p></td>
</tr>
</tbody>
</table>

## **Terminal 2 — USSD Gateway (port 8001)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/ussd-gateway</p>
<p>source ../venv/bin/activate</p>
<p>source ../.env</p>
<p>uvicorn ussd:app --host 0.0.0.0 --port 8001 --reload</p>
<p># Test the USSD menu:</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text='</p>
<p># Expected response:</p>
<p># CON Ubuntu Pay *384#</p>
<p># 1. Send Money</p>
<p># 2. My Balance</p>
<p># 3. Save Money</p>
<p># 0. Lock Wallet</p></td>
</tr>
</tbody>
</table>

## **Terminal 3 — Dashboard Website (port 3000)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>cd ~/UbuntuPay/dashboard</p>
<p>python3 -m http.server 3000</p>
<p># Open in browser:</p>
<p># http://localhost:3000 → Landing page</p>
<p># http://localhost:3000/demo-ussd.html → Nokia USSD Demo</p>
<p># http://localhost:3000/backend.html → Developer Console</p></td>
</tr>
</tbody>
</table>

<table style="width:96%;">
<colgroup>
<col style="width: 2%" />
<col style="width: 94%" />
</colgroup>
<tbody>
<tr>
<td></td>
<td><p><strong>Quick status check</strong></p>
<p>With all three servers running, open
http://localhost:8000/backend.html. The header should show Oracle: Nokia
● Real (or Sim) in green and WS: live in green. If Oracle shows OFFLINE,
check Terminal 1 for error messages.</p></td>
</tr>
</tbody>
</table>

# **8. Nokia Test Phone Numbers**

In simulation mode (no NOKIA_API_KEY), specific phone numbers trigger
different Nokia signal patterns. Use these to demonstrate ALLOW and
BLOCK scenarios in the demo.

|  |  |  |  |  |  |
|----------------|------------|----------|----------|----------|---------------|
| **Phone Number** | **Device Swap** | **Roaming** | **Country** | **Score** | **Result** |
| +99999991001 | false | false | KE | 94/100 | **ALLOW ✓** |
| +99999991000 | TRUE | TRUE | HU | 0/100 | **BLOCK ✗** |
| +99999991002 | false | false | NG | 72/100 | **ALLOW ✓** |

Numbers ending in 99 → BLOCK · Numbers ending in 88 → device changed ·
Numbers ending in 55 → roaming

<table style="width:96%;">
<colgroup>
<col style="width: 2%" />
<col style="width: 94%" />
</colgroup>
<tbody>
<tr>
<td></td>
<td><p><strong>Real Nokia numbers</strong></p>
<p>With a valid NOKIA_API_KEY, use the actual Safaricom simulator
numbers from the Nokia developer portal: +99999991001 triggers ALLOW and
+99999991000 triggers BLOCK on the real Nokia network.</p></td>
</tr>
</tbody>
</table>

# **9. End-to-End Test**

With all three servers running, test the complete flow — Nokia oracle →
Gemini scoring → Polygon settlement — using curl or the Developer
Console.

## **9.1 Trust Check (B2B Oracle)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>curl -X POST http://localhost:8000/trust/check \</p>
<p>-H 'Content-Type: application/json' \</p>
<p>-d '{</p>
<p>"phone": "+99999991001",</p>
<p>"use_case": "payment",</p>
<p>"amount": 38.46,</p>
<p>"client_id": "demo"</p>
<p>}'</p>
<p># Expected response:</p>
<p># {</p>
<p># "score": 94,</p>
<p># "recommendation": "ALLOW",</p>
<p># "confidence": "HIGH",</p>
<p># "reasoning": "All 6 Nokia signals clean...",</p>
<p># "signals": {</p>
<p># "device_changed": false,</p>
<p># "sim_swapped": false,</p>
<p># "roaming": false,</p>
<p># "country": "KE",</p>
<p># "kyc_score": 0.85,</p>
<p># "near_agent": true,</p>
<p># "number_verified": true,</p>
<p># "nokia_response_ms": 312</p>
<p># }</p>
<p># }</p></td>
</tr>
</tbody>
</table>

## **9.2 Full Transfer (KES → USDC → Polygon → NGN)**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p>curl -X POST http://localhost:8000/transfer \</p>
<p>-H 'Content-Type: application/json' \</p>
<p>-d '{</p>
<p>"sender": "+99999991001",</p>
<p>"receiver": "+234803000001",</p>
<p>"name": "John",</p>
<p>"kes": 5000,</p>
<p>"pin": "1234"</p>
<p>}'</p>
<p># Expected response:</p>
<p># {</p>
<p># "status": "confirmed",</p>
<p># "tx_hash": "0x7a2f...",</p>
<p># "kes_sent": 5000,</p>
<p># "usdc_settled": 38.37,</p>
<p># "ngn_received": 59780,</p>
<p># "score": 94</p>
<p># }</p></td>
</tr>
</tbody>
</table>

## **9.3 USSD Simulation**

<table style="width:96%;">
<colgroup>
<col style="width: 96%" />
</colgroup>
<tbody>
<tr>
<td><p># Main menu</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text='</p>
<p># Select option 1 (Send Money)</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text=1'</p>
<p># Enter recipient number</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text=1*+234803000001'</p>
<p># Enter amount</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text=1*+234803000001*5000'</p>
<p># Confirm (1 = yes)</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text=1*+234803000001*5000*1'</p>
<p># Full flow with PIN</p>
<p>curl
'http://localhost:8001/simulate?phone=+99999991001&amp;text=1*+234803000001*John*5000*1*1234'</p></td>
</tr>
</tbody>
</table>

# **10. Troubleshooting**

|  |  |
|------------------------|---------------------------------------------|
| **Error** | **Fix** |
| ModuleNotFoundError: No module named 'fastapi' | Virtual environment not activated. Run: source venv/bin/activate |
| Connection refused :8000 | Trust Oracle not running. Start it: uvicorn main:app --port 8000 |
| Web3 cannot reach Polygon Amoy | Check POLYGON_RPC_URL in .env. Try backup RPC: https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY |
| Contract reverts: Trust score too low | Nokia score below MIN_TRUST_SCORE (default 70). Use phone +99999991001 which scores 94. |
| USDC transfer failed | Agent wallet has no test USDC. Fund at faucet.circle.com with the AGENT_ADDRESS. |
| Gemini API error / model not found | GEMINI_API_KEY missing or model name incorrect. Check: gemini-3.1-flash-lite-preview is the exact string. |
| export \# Polygon Amoy in .env causes error | Delete the line 'export \# Polygon Amoy Testnet RPC and USDC' — it is a comment that was accidentally exported. |
| forge: command not found | Foundry not installed or not in PATH. Run: curl -L https://foundry.paradigm.xyz \| bash && foundryup |

# **11. Key Links & Resources**

|  |  |
|-----------------------|-----------------------------------------------|
| **Resource** | **URL** |
| TrustGate.sol on Polygonscan | amoy.polygonscan.com/address/0x1373A4c5779536A7265a5a4EC70Bc288A208581A#code |
| Polygon Amoy Faucet (MATIC) | faucet.polygon.technology |
| Circle USDC Faucet | faucet.circle.com |
| Nokia Network as Code | networkascode.nokia.io |
| Google AI Studio (Gemini key) | aistudio.google.com |
| Yellow Card Sandbox | yellowcard.io/developers |
| Foundry Book | book.getfoundry.sh |
| CAMARA API Docs | camaraproject.org |
| FastAPI Docs | fastapi.tiangolo.com |

*Ubuntu Pay · Africa Ignite 2026 · Theme 6: Open Innovation ·
Shortlisted*

**The Network Is The Bank.**
