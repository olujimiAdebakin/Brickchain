// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/access/AccessManager.sol";

contract GrantRoles is Script {
    /// @notice Grants roles to specified addresses
    /// @dev Run with admin's private key
    function run() external {
        bytes32 adminPrivateKey = vm.envBytes32("PRIVATE_KEY");
        address admin = vm.addr(uint256(adminPrivateKey));
        console.log("Admin address:", admin);

        address accessManager = vm.envAddress("ACCESS_MANAGER_ADDRESS");
        address auditor = vm.envAddress("AUDITOR_ADDRESS");
        address realtor = vm.envAddress("REALTOR_ADDRESS");
        console.log("AccessManager address:", accessManager);
        console.log("Auditor address:", auditor);
        console.log("Realtor address:", realtor);

        require(accessManager != address(0), "Invalid AccessManager address");
        require(auditor != address(0), "Invalid auditor address");
        require(realtor != address(0), "Invalid realtor address");

        vm.startBroadcast(uint256(adminPrivateKey));
        AccessManager am = AccessManager(accessManager);
        am.grantRole(am.AUDITOR_ROLE(), auditor);
        am.grantRole(am.REALTOR_ROLE(), realtor);
        console.log("AUDITOR_ROLE granted to:", auditor);
        console.log("REALTOR_ROLE granted to:", realtor);
        vm.stopBroadcast();
    }
}