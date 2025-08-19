// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../src/kyc/KYCManager.sol";

contract KYCManagerTest is Test {
    KYCManager public kycManager;
    address admin = address(0xA11);
    address auditor = address(0xA22);
    address realtor = address(0xB33);
    address realtor2 = address(0xB44);
    address notAdmin = address(0xBAD);

    function setUp() public {
        // Deploy KYCManager with admin
        kycManager = new KYCManager(admin);

        // Grant auditor role to auditor
        vm.startPrank(admin);
        kycManager.grantRole(kycManager.AUDITOR_ROLE(), auditor);
        vm.stopPrank();

        console.log("KYCManager deployed at:", address(kycManager));
        console.log("Admin:", admin);
        console.log("Auditor:", auditor);
    }

    function testKYCSubmission() public {
        console.log("=== KYC Submission Test ===");

        // Expect event emission
        vm.expectEmit(true, false, false, true);
        emit KYCManager.KYCSubmitted(realtor, block.timestamp);

        // Submit KYC
        vm.prank(realtor);
        kycManager.submitKYC("Pelumi", "AdetoyePelui@email.com", "123456789", "08012345678");
        console.log("KYC submitted for:", realtor);

        // Check stored data
        KYCManager.KYCData memory data = kycManager.getKYCData(realtor);
        console.log("Current status before resubmission:", uint8(data.status));
        assertEq(data.name, "Pelumi");
        console.log("Name:", data.name);
        assertEq(data.email, "AdetoyePelui@email.com");
        console.log("Email:", data.email);
        assertEq(data.nin, "123456789");
        console.log("Nin:", data.nin);
        assertEq(data.phone, "08012345678");
        console.log("Phone:", data.phone);
        assertEq(uint8(data.status), uint8(KYCManager.KYCStatus.Pending));
        assertEq(data.submittedAt, block.timestamp);

        // Cannot resubmit while pending

        // Second submission (must prank again!)
        vm.prank(realtor);
        vm.expectRevert("KYC already submitted or approved");
        kycManager.submitKYC("Pelumi", "AdetoyePelui@email.com", "123456789", "08012345678");
        console.log("Resubmission while pending correctly reverted");
    }

    function testKYCSubmissionAfterRejection() public {
        console.log("=== KYC Resubmission After Rejection Test ===");
        vm.prank(realtor);
        kycManager.submitKYC("Bob", "bob@email.com", "987654321", "08087654321");

        // Fast-forward 1 day for approval/rejection
        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        kycManager.rejectKYC(realtor);
        console.log("KYC rejected for:", realtor);

        // Can resubmit after rejection
        vm.prank(realtor);
        kycManager.submitKYC("Pelumi", "bob@email.com", "987654321", "08087654321");
        KYCManager.KYCData memory data = kycManager.getKYCData(realtor);
        assertEq(uint8(data.status), uint8(KYCManager.KYCStatus.Pending));
        console.log("KYC resubmitted after rejection for:", realtor);
    }

    function testApproveKYCByAdmin() public {
        console.log("=== KYC Approval by Admin Test ===");
        vm.prank(realtor);
        kycManager.submitKYC("Obed_Chukwu", "chukwu@email.com", "111222333", "08011122233");

        // Try to approve before 24h
        vm.prank(admin);
        vm.expectRevert("Wait 24hrs after KYC");
        kycManager.approveKYC(realtor);
        console.log("Approval before 24h correctly reverted");

        // Fast-forward 1 day
        vm.warp(block.timestamp + 1 days);

        // Approve by admin
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit KYCManager.KYCApproved(realtor, block.timestamp);
        kycManager.approveKYC(realtor);
        console.log("KYC approved for:", realtor);

        KYCManager.KYCData memory data = kycManager.getKYCData(realtor);
        assertEq(uint8(data.status), uint8(KYCManager.KYCStatus.Approved));
        assertTrue(kycManager.hasRole(kycManager.REALTOR_ROLE(), realtor));
        assertTrue(kycManager.isKYCApproved(realtor));
    }

    function testApproveKYCByAuditor() public {
        console.log("=== KYC Approval by Auditor Test ===");
        vm.prank(realtor2);
        kycManager.submitKYC("Tali", "tali@email.com", "555666777", "08055566677");
        vm.warp(block.timestamp + 1 days);

        vm.prank(auditor);
        kycManager.approveKYC(realtor2);
        console.log("KYC approved by auditor for:", realtor2);

        KYCManager.KYCData memory data = kycManager.getKYCData(realtor2);
        assertEq(uint8(data.status), uint8(KYCManager.KYCStatus.Approved));
        assertTrue(kycManager.hasRole(kycManager.REALTOR_ROLE(), realtor2));
    }

    function testApproveKYCOnlyAdminOrAuditor() public {
        console.log("=== Only Admin or Auditor Can Approve KYC Test ===");
        vm.prank(realtor);
        kycManager.submitKYC("Amaka", "amak@email.com", "888999000", "08088899900");
        vm.warp(block.timestamp + 1 days);

        vm.prank(notAdmin);
        vm.expectRevert();
        kycManager.approveKYC(realtor);
        console.log("Non-admin/auditor approval correctly reverted");
    }

    function testRejectKYC() public {
        console.log("=== KYC Rejection Test ===");
        vm.prank(realtor);
        kycManager.submitKYC("Fitech", "fitech@email.com", "444555666", "08044455566");
        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit KYCManager.KYCRejected(realtor, block.timestamp);
        kycManager.rejectKYC(realtor);
        console.log("KYC rejected for:", realtor);

        KYCManager.KYCData memory data = kycManager.getKYCData(realtor);
        assertEq(uint8(data.status), uint8(KYCManager.KYCStatus.Rejected));
        assertFalse(kycManager.isKYCApproved(realtor));
    }

    function testBatchApproveKYC() public {
        console.log("=== Batch KYC Approval Test ===");
        address[] memory realtors = new address[](2);
        realtors[0] = realtor;
        realtors[1] = realtor2;

        vm.prank(realtor);
        kycManager.submitKYC("Abigael", "abigael@email.com", "111111111", "08011111111");
        vm.prank(realtor2);
        kycManager.submitKYC("Adebakin", "adebakin@email.com", "222222222", "08022222222");
        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        kycManager.batchApproveKYC(realtors);
        console.log("Batch KYC approved for:", realtor, "and", realtor2);

        KYCManager.KYCData memory data1 = kycManager.getKYCData(realtor);
        KYCManager.KYCData memory data2 = kycManager.getKYCData(realtor2);
        assertEq(uint8(data1.status), uint8(KYCManager.KYCStatus.Approved));
        assertEq(uint8(data2.status), uint8(KYCManager.KYCStatus.Approved));
    }

    function testBatchRejectKYC() public {
        console.log("=== Batch KYC Rejection Test ===");
        address[] memory realtors = new address[](2);
        realtors[0] = realtor;
        realtors[1] = realtor2;

        vm.prank(realtor);
        kycManager.submitKYC("Lekan", "lekan@email.com", "333333333", "08033333333");
        vm.prank(realtor2);
        kycManager.submitKYC("Olujimi", "jimi@email.com", "444444444", "08044444444");
        vm.warp(block.timestamp + 1 days);

        vm.prank(auditor);
        kycManager.batchRejectKYC(realtors);
        console.log("Batch KYC rejected for:", realtor, "and", realtor2);

        KYCManager.KYCData memory data1 = kycManager.getKYCData(realtor);
        KYCManager.KYCData memory data2 = kycManager.getKYCData(realtor2);
        assertEq(uint8(data1.status), uint8(KYCManager.KYCStatus.Rejected));
        assertEq(uint8(data2.status), uint8(KYCManager.KYCStatus.Rejected));
    }

    function testViewFunctions() public {
        console.log("=== View Functions Test ===");
        vm.prank(realtor);
        kycManager.submitKYC("Wirtz", "wirtz@email.com", "555555555", "08055555555");
        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        kycManager.approveKYC(realtor);

        assertTrue(kycManager.isKYCApproved(realtor));
        assertEq(uint8(kycManager.getKYCStatus(realtor)), uint8(KYCManager.KYCStatus.Approved));
        KYCManager.KYCData memory data = kycManager.getKYCData(realtor);
        assertEq(data.name, "Wirtz");
        console.log("View functions assertions passed for:", realtor);
    }
}
