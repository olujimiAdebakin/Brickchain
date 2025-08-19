
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/escrow/Escrow.sol";

contract DeployEscrow is Script {
    /// @notice Deploys the Escrow contract for Brickchain
    /// @dev Loads constructor arguments from environment variables
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address kycManager = vm.envAddress("KYC_MANAGER_ADDRESS");
        console.log("Admin address:", admin);
        console.log("KYCManager address:", kycManager);

        require(admin != address(0), "Invalid admin address");
        require(kycManager != address(0), "Invalid KYCManager address");
        console.log("Constructor arguments validated successfully");

        vm.startBroadcast(deployerPrivateKey);
        Escrow escrow = new Escrow(admin, kycManager);
        console.log("Escrow deployed to:", address(escrow));
        vm.stopBroadcast();

        console.log("Escrow deployment completed by:", deployer);
    }
}