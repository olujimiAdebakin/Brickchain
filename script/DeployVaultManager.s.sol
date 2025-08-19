
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/vault/VaultManager.sol";

contract DeployVaultManager is Script {
    /// @notice Deploys the VaultManager contract for Brickchain
    /// @dev Loads constructor arguments from environment variables
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address escrow = vm.envAddress("ESCROW_ADDRESS");
        address vault = vm.envAddress("VAULT_ADDRESS");
        console.log("Admin address:", admin);
        console.log("Escrow address:", escrow);
        console.log("Vault address:", vault);

        require(admin != address(0), "Invalid admin address");
        require(escrow != address(0), "Invalid escrow address");
        require(vault != address(0), "Invalid vault address");
        console.log("Constructor arguments validated successfully");

        vm.startBroadcast(deployerPrivateKey);
        VaultManager vaultManager = new VaultManager(admin, escrow, vault);
        console.log("VaultManager deployed to:", address(vaultManager));
        vm.stopBroadcast();

        console.log("VaultManager deployment completed by:", deployer);
    }
}