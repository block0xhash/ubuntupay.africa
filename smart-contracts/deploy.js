
require("dotenv").config({ path: "../.env" });
const { ethers } = require("ethers");
const fs = require("fs");

async function main() {
    // 1. Setup Provider and Wallet
    const provider = new ethers.JsonRpcProvider(process.env.POLYGON_RPC_URL);
    const wallet = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY, provider);

    console.log("🚀 Deploying TrustGate with account:", wallet.address);

    // 2. Load Compiled Contract (ABI and Bytecode)
    // Note: You get these from Remix or 'npx hardhat compile'
    const abi = JSON.parse(fs.readFileSync("./TrustGate.abi.json", "utf8"));
    const binary = fs.readFileSync("./TrustGate.bin", "utf8");

    // 3. Define Constructor Arguments
    // These must match your TrustGate.sol constructor(address _oracle, address _usdc)
    const oracleAddress = "0xYour_Oracle_Address_From_Gen_Wallet";
    const usdcAddress = "0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582"; // Polygon Amoy Testnet USDC

    // 4. Create Contract Factory and Deploy
    const factory = new ethers.ContractFactory(abi, binary, wallet);

    console.log("⏳ Sending deployment transaction...");
    const contract = await factory.deploy(oracleAddress, usdcAddress);

    await contract.waitForDeployment();
    const deployedAddress = await contract.getAddress();

    console.log("\n✅ TrustGate Deployed Successfully!");
    console.log("----------------------------------------------");
    console.log("Contract Address:", deployedAddress);
    console.log("Polygonscan: https://amoy.polygonscan.com/address/" + deployedAddress);
    console.log("----------------------------------------------");
    console.log("\n👉 ACTION: Copy the Contract Address into your .env file as TRUST_GATE_ADDRESS");
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
