// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/factory/TokenFactory.sol";

contract DeployTokenFactory is Script {
    /// @notice Deploys the TokenFactory contract for Brickchain
    /// @dev Loads registry and AccessManager addresses from environment variables and deploys TokenFactory
    function run() external {
        // @dev Load private key and derive deployer address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        // @dev Load constructor arguments from environment variables
        address registry = vm.envAddress("REGISTRY_ADDRESS");
        address accessManager = vm.envAddress("ACCESS_MANAGER_ADDRESS");
        console.log("Registry address:", registry);
        console.log("AccessManager address:", accessManager);

        // @notice Validate constructor arguments
        // @dev Ensure non-zero addresses
        require(registry != address(0), "Invalid registry address");
        require(accessManager != address(0), "Invalid AccessManager address");
        console.log("Constructor arguments validated successfully");

        // @notice Start broadcasting transactions
        // @dev Use deployer’s private key for signing
        vm.startBroadcast(deployerPrivateKey);

        // @notice Deploy TokenFactory contract
        // @dev Pass registry and AccessManager addresses to constructor
        TokenFactory tokenFactory = new TokenFactory(registry, accessManager);
        console.log("TokenFactory deployed to:", address(tokenFactory));

        // @dev Stop broadcasting transactions
        vm.stopBroadcast();

        // @notice Log deployment completion
        // @dev Confirm deployment success
        console.log("TokenFactory deployment completed by:", deployer);
    }
}