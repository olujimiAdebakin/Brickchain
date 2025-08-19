
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/kyc/KYCManager.sol";

contract ApproveKYC is Script {
    /// @notice Approves KYC for a realtor
    /// @dev Run with admin's private key, specify realtor address
    function run() external {
        bytes32 adminPrivateKey = vm.envBytes32("PRIVATE_KEY");
        address admin = vm.addr(uint256(adminPrivateKey));
        console.log("Admin address:", admin);

        address kycManager = vm.envAddress("KYC_MANAGER_ADDRESS");
        address realtor = vm.envAddress("REALTOR_ADDRESS");
        console.log("KYCManager address:", kycManager);
        console.log("Realtor address:", realtor);

        require(kycManager != address(0), "Invalid KYCManager address");
        require(realtor != address(0), "Invalid realtor address");

        vm.startBroadcast(uint256(adminPrivateKey));
        KYCManager km = KYCManager(kycManager);
        km.approveKYC(realtor);
        console.log("KYC approved for:", realtor);
        vm.stopBroadcast();
    }
}