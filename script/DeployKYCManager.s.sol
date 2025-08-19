// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/kyc/KYCManager.sol";

contract DeployKYCManager is Script {
    /// @notice Deploys the KYCManager contract for Brickchain
    /// @dev Loads admin address from environment variables and deploys KYCManager
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        address admin = vm.envAddress("ADMIN_ADDRESS");
        console.log("Admin address:", admin);

        require(admin != address(0), "Invalid admin address");
        console.log("Admin address validated successfully");

        vm.startBroadcast(deployerPrivateKey);
        KYCManager kycManager = new KYCManager(admin);
        console.log("KYCManager deployed to:", address(kycManager));
        vm.stopBroadcast();

        console.log("KYCManager deployment completed by:", deployer);
    }
}