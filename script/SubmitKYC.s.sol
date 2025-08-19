// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/kyc/KYCManager.sol";

contract SubmitKYC is Script {
    /// @notice Submits KYC for a realtor
    /// @dev Run with realtor's private key and address
    function run() external {
        bytes32 realtorPrivateKey = vm.envBytes32("REALTOR_PRIVATE_KEY");
        address realtor = vm.envAddress("REALTOR_ADDRESS");
        console.log("Realtor address:", realtor);

        address kycManager = vm.envAddress("KYC_MANAGER_ADDRESS");
        console.log("KYCManager address:", kycManager);

        require(kycManager != address(0), "Invalid KYCManager address");
        require(realtor != address(0), "Invalid realtor address");

        vm.startBroadcast(uint256(realtorPrivateKey));
        KYCManager km = KYCManager(kycManager);
        km.submitKYC("olujimi", "olujimi@example.com", "12345667849", "12332167890");
        console.log("KYC submitted for:", realtor);
        vm.stopBroadcast();

         // Get the struct, then log its fields
        KYCManager.KYCData memory data = km.getKYCData(realtor);
        console.log("KYC Data for:", realtor);
        console.log("  Name:", data.name);
        console.log("  Email:", data.email);
        console.log("  NIN:", data.nin);
        console.log("  Phone:", data.phone);
        console.log("  SubmittedAt:", data.submittedAt);
        console.log("  Status:", uint256(data.status));
    }
}