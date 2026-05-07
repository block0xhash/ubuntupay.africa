// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 🚀 FIXED: Using named imports to follow linter best practices
import {Script} from "forge-std/Script.sol";
import {TrustGate} from "../src/TrustGate.sol";

contract DeployTrustGate is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        address usdc = vm.envAddress("USDC_TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploys the Golden Edition Protocol
        new TrustGate(oracle, usdc);

        vm.stopBroadcast();
    }
}
