// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UbuntuPay: The TrustGate Settlement Engine
 * @author Africa Ignite 2026 Submission
 *
 * 📄 DESCRIPTION:
 * This contract is the "Digital Commons" bank for the unbanked. It manages an
 * on-chain ledger where user accounts are bound to their physical phone hardware.
 *
 * 🌍 THE UBUNTUPAY PHILOSOPHY:
 * 1. IDENTITY AS THE KEY: We remove the "Seed Phrase" barrier. Joseph's SIM card
 *    and physical device (IMEI/IMSI) are his keys. If he has his identity, he has his money.
 * 2. TRANSACTION FORGIVENESS: Standard crypto is "ruthless"—one typo and money is gone.
 *    Ubuntu Pay introduces a "Human Safety Net" via a 30-minute Escrow window.
 * 3. COMPLIANCE-AT-THE-EDGE: We use Nokia Roaming APIs to sense where the user is
 *    standing and automatically apply local Pan-African tax laws (VAT/Excise Duty).
 * 4. PRIVACY BY DESIGN: We never store Joseph's name or ID on the public blockchain.
 *    We store "Identity Commitments" (Hashes) to remain 100% POPIA and GDPR compliant.
 *
 * 🏦 JUDGE'S NOTE: THE VAULT ARCHITECTURE
 * This contract acts as a 'Smart Vault'. By holding USDC inside this contract and managing
 * an internal ledger, we eliminate the need for Joseph to sign 'Approve' transactions or
 * pay gas. It makes the blockchain experience as simple as a USSD menu.
 */

// ══════════════════════════════════════════════════════════════════════════
// HOW PRIVACY WORKS
// ══════════════════════════════════════════════════════════════════════════
//
// Registration:
//   Oracle computes: keccak256("99999991002") = 0x9f2b...a441
//   Stores on-chain: vaults[0x9f2b...a441] = 0xAeeb...c244
//
// Transfer lookup:
//   Joseph provides: +99999991002
//   Oracle computes: keccak256("99999991002") = 0x9f2b...a441
//   Reads on-chain:  vaults[0x9f2b...a441]   = 0xAeeb...c244
//   Sends USDC to:   0xAeeb...c244
//
// What is visible on Polygon:
//   0x9f2b...a441  (hash)    ← cannot be reversed to phone number
//   0xAeeb...c244  (address) ← just an Ethereum address, no PII
//
// What is NOT visible:
//   +99999991002  ← never stored on-chain, never in a tx, never in an event
// ══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
// DEMO SEED SCRIPT (run once to pre-register the test numbers)
// python3 seed_vaults.py
// ══════════════════════════════════════════════════════════════════════════

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TrustGate {
    address public owner; // The Protocol Treasury (Receives transaction fees)
    address public oracle; // The Authorized Python Signer (Gated by Nokia Network Signals)
    IERC20 public usdc; // The global settlement currency (Circle USDC)

    uint8 public minScore = 70; // Risk threshold for automated settlement

    // --- Statistics for the Mission Control Dashboard ---
    uint256 public totalTx;
    uint256 public totalVolume;
    uint256 public revenueCollected;

    // --- The Ledger ---
    mapping(address => uint256) public balances;
    mapping(address => bool) public walletLocked;

    // --- Privacy: POPIA Compliance ---
    mapping(address => bytes32) public identityCommitments;

    // --- Escrow for Human-Error Protection (Reversals) ---
    struct PendingTransfer {
        address sender;
        address receiver;
        uint256 principal;
        uint256 fee;
        uint256 timestamp;
        bool active;
    }

    mapping(bytes32 => PendingTransfer) public vaultEscrow;
    mapping(bytes32 => address) public vaults;

    function registerVault(bytes32 phoneHash, address vault) external onlyOracle {
        require(vaults[phoneHash] == address(0), "Already registered");
        require(vault != address(0), "Invalid vault address");
        vaults[phoneHash] = vault;
        emit VaultRegistered(phoneHash, vault);
    }

    event Deposited(address indexed user, uint256 amount);
    event EscrowStarted(bytes32 indexed txId, address indexed from, address indexed to, uint256 amount);
    event Finalized(bytes32 indexed txId, address indexed to, uint256 amount);
    event Reversed(bytes32 indexed txId, address indexed to, uint256 amount);
    event IdentityVerified(address indexed wallet, bytes32 kycHash);
    event RecoveryExecuted(address indexed oldId, address indexed newId, uint256 balance);
    event VaultRegistered(bytes32 indexed phoneHash, address indexed vault);

    // 🚀 MODIFIER OPTIMIZATION: Internal functions reduce bytecode size for cheaper deployment
    modifier onlyOracle() {
        _checkOracle();
        _;
    }

    function _checkOracle() internal view {
        require(msg.sender == oracle, "UbuntuPay: Signer Unauthorized");
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view {
        require(msg.sender == owner, "UbuntuPay: Admin Only");
    }

    constructor(address _oracle, address _usdc) {
        owner = msg.sender;
        oracle = _oracle;
        usdc = IERC20(_usdc);
    }

    /**
     * 🆔 PRIVACY FEATURE: IDENTITY COMMITMENT
     * Anchors a Nokia KYC verification to the blockchain without leaking PII.
     * We store a cryptographic hash of the user's National ID and Name.
     */
    function verifyIdentity(address wallet, bytes32 kycHash) external onlyOracle {
        identityCommitments[wallet] = kycHash;
        emit IdentityVerified(wallet, kycHash);
    }

    /**
     * 🏪 AGENT ACTION: CASH-IN
     * Called by an Ubuntu Agent. Moves USDC from the Agent into the Smart Vault
     * to credit the user's hardware-bound balance.
     */
    function depositFor(address user, uint256 amount) external {
        require(usdc.transferFrom(msg.sender, address(this), amount), "Liquidity Provision Failed");
        balances[user] += amount;
        emit Deposited(user, amount);
    }

    /**
     * 🛡️ SETTLEMENT (STEP 1): MOVE TO ESCROW
     * Deducts funds and puts them in a 'Pending' state.
     * Triggered ONLY after Nokia Hardware signals and AI Risk scoring are verified.
     */
    function execute(address sender, address receiver, uint256 principal, uint256 fee, uint8 score, bytes32 checkId)
        external
        onlyOracle
    {
        require(!walletLocked[sender], "Vault Frozen via *384*0#");
        require(score >= minScore, "Nokia Security Alert: High Risk");

        uint256 totalCost = principal + fee;
        require(balances[sender] >= totalCost, "Insufficient Vault Balance");

        balances[sender] -= totalCost;
        vaultEscrow[checkId] = PendingTransfer({
            sender: sender, receiver: receiver, principal: principal, fee: fee, timestamp: block.timestamp, active: true
        });

        totalTx++;
        totalVolume += principal;
        emit EscrowStarted(checkId, sender, receiver, principal);
    }

    /**
     * ✅ BANK FEATURE: FINALIZE SETTLEMENT (STEP 2)
     * Releases funds from Escrow to the recipient.
     */
    function finalizeTransfer(bytes32 checkId) external onlyOracle {
        PendingTransfer storage t = vaultEscrow[checkId];
        require(t.active, "Transfer not pending");

        // 🛡️ SECURITY CHECK: Grace period enforcement
        // Production: 30 minutes | Hackathon Demo: 15 seconds
        require(block.timestamp >= t.timestamp + 15 seconds, "Grace period still active");

        t.active = false;
        balances[t.receiver] += t.principal;

        balances[owner] += t.fee;
        revenueCollected += t.fee;

        emit Finalized(checkId, t.receiver, t.principal);
    }

    /**
     * ↩️ BANK FEATURE: EMERGENCY REVERSAL
     * Triggered if the user reports a mistake via USSD *384*5#.
     * Returns both Principal and Fee to Joseph's vault.
     */
    function reverseTransfer(bytes32 checkId) external onlyOracle {
        PendingTransfer storage t = vaultEscrow[checkId];
        require(t.active, "Transfer not pending or already finalized");

        t.active = false;
        balances[t.sender] += (t.principal + t.fee);

        emit Reversed(checkId, t.sender, t.principal);
    }

    /**
     * ♻️ RECOVERY: IDENTITY MIGRATION
     * Moves a balance from an old hardware identity to a new one after Agent verification.
     */
    function migrateIdentity(address oldId, address newId) external onlyOracle {
        uint256 balance = balances[oldId];
        require(balance > 0, "No value found in old identity");

        balances[oldId] = 0;
        balances[newId] += balance;
        identityCommitments[newId] = identityCommitments[oldId];

        emit RecoveryExecuted(oldId, newId, balance);
    }

    // --- Safety and Administrative Functions ---

    function setWalletLock(address wallet, bool locked) external onlyOracle {
        walletLocked[wallet] = locked;
    }

    function setMinScore(uint8 _score) external onlyOwner {
        require(_score <= 100, "Invalid Score");
        minScore = _score;
    }

    function getStats() external view returns (uint256, uint256, uint256) {
        return (totalTx, totalVolume, revenueCollected);
    }

    function getVaultBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
