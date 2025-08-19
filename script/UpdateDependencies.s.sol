// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/vault/Vault.sol";
import "../src/factory/TokenFactory.sol";

contract UpdateDependencies is Script {
    /// @notice Updates Registry address in Vault and TokenFactory for Brickchain
    /// @dev Replaces placeholder Registry address with the actual deployed address
    function run() external {
        bytes32 deployerPrivateKey = vm.envBytes32("PRIVATE_KEY");
        address deployer = vm.addr(uint256(deployerPrivateKey));
        console.log("Deployer address:", deployer);

        address vault = vm.envAddress("VAULT_ADDRESS");
        address tokenFactory = vm.envAddress("TOKEN_FACTORY_ADDRESS");
        address registry = vm.envAddress("REGISTRY_ADDRESS");
        console.log("Vault address:", vault);
        console.log("TokenFactory address:", tokenFactory);
        console.log("Registry address:", registry);

        require(vault != address(0), "Invalid Vault address");
        require(tokenFactory != address(0), "Invalid TokenFactory address");
        require(registry != address(0), "Invalid Registry address");

        vm.startBroadcast(uint256(deployerPrivateKey));
        Vault(vault).updateRegistry(registry);
        TokenFactory(tokenFactory).setRegistry(registry);
        console.log("Vault registry updated to:", registry);
        console.log("TokenFactory registry updated to:", registry);
        vm.stopBroadcast();

        console.log("Dependencies updated by:", deployer);
    }
}