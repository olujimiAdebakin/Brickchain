// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/escrow/Escrow.sol";

contract WhitelistVaultManager is Script {
    /// @notice Whitelists VaultManager in Escrow for Brickchain
    /// @dev Allows VaultManager to withdraw funds from Escrow
    function run() external {
        bytes32 deployerPrivateKey = vm.envBytes32("PRIVATE_KEY");
        address deployer = vm.addr(uint256(deployerPrivateKey));
        console.log("Deployer address:", deployer);

        address escrow = vm.envAddress("ESCROW_ADDRESS");
        address vaultManager = vm.envAddress("VAULT_MANAGER_ADDRESS");
        console.log("Escrow address:", escrow);
        console.log("VaultManager address:", vaultManager);

        require(escrow != address(0), "Invalid Escrow address");
        require(vaultManager != address(0), "Invalid VaultManager address");

        vm.startBroadcast(uint256(deployerPrivateKey));
        Escrow(escrow).updateVaultManager(vaultManager, true);
        console.log("VaultManager whitelisted in Escrow:", vaultManager);
        vm.stopBroadcast();

        console.log("VaultManager whitelisting completed by:", deployer);
    }
}