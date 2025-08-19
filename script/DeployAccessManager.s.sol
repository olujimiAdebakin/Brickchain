// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/access/AccessManager.sol";

contract DeployAccessManager is Script {
    /// @notice Deploys the AccessManager contract for Brickchain
    /// @dev Loads admin address from environment variables and deploys AccessManager
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        address admin = vm.envAddress("ADMIN_ADDRESS");
        console.log("Admin address:", admin);

        require(admin != address(0), "Invalid admin address");
        console.log("Admin address validated successfully");

        vm.startBroadcast(deployerPrivateKey);
        AccessManager accessManager = new AccessManager(admin);
        console.log("AccessManager deployed to:", address(accessManager));
        vm.stopBroadcast();

        console.log("AccessManager deployment completed by:", deployer);
    }
}