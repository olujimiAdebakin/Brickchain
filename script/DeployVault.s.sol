// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/vault/Vault.sol";

contract DeployVault is Script {
    /// @notice Deploys the Vault contract for Brickchain
    /// @dev Loads constructor arguments from environment variables
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address kycManager = vm.envAddress("KYC_MANAGER_ADDRESS");
        address registry = vm.envAddress("REGISTRY_ADDRESS");
        address stablecoin = vm.envAddress("STABLECOIN_ADDRESS");
        console.log("Admin address:", admin);
        console.log("KYCManager address:", kycManager);
        console.log("Registry address (placeholder):", registry);
        console.log("Stablecoin address:", stablecoin);

        require(admin != address(0), "Invalid admin address");
        require(kycManager != address(0), "Invalid KYCManager address");
        require(registry != address(0), "Invalid registry address");
        require(stablecoin != address(0), "Invalid stablecoin address");
        console.log("Constructor arguments validated successfully");

        vm.startBroadcast(deployerPrivateKey);
        Vault vault = new Vault(admin, kycManager, registry, stablecoin);
        console.log("Vault deployed to:", address(vault));
        vm.stopBroadcast();

        console.log("Vault deployment completed by:", deployer);
    }
}