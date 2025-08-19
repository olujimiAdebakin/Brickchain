// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../src/tokens/PropertyToken.sol";
import "../src/access/AccessManager.sol";
import "../test/mocks/MockAccessManager.sol";

contract PropertyTokenTest is Test {
    PropertyToken public token;
    // AccessManager public accessManager;
    MockAccessManager public accessManager;
    address vault = address(0xBEEF);
    address notOwner = address(0xBAD);

    function setUp() public {
        // accessManager = new AccessManager(address(this));

        accessManager = new MockAccessManager();
        token = new PropertyToken(
            address(accessManager),
            "Property Name",
            "PROP1",
            1000 ether,
            "Property Token",
            "PTKN",
            "ipfs://property-metadata",
            vault
        );
        console.log("Token deployed at:", address(token));
        console.log("Vault (owner):", vault);
    }

    function testDeployment() public {
        console.log("=== Deployment Test ===");
        assertEq(token.propertyName(), "Property Name");
        assertEq(token.propertySymbol(), "PROP1");
        assertEq(token.propertyURI(), "ipfs://property-metadata");
        assertEq(token.getAccessManager(), address(accessManager));
        assertEq(token.owner(), vault);
        assertEq(token.balanceOf(vault), 1000 ether);
        console.log("Deployment assertions passed");
    }

    function testTransferWhenNotPaused() public {
        console.log("=== Transfer When Not Paused ===");
        vm.prank(vault);
        token.transfer(notOwner, 100 ether);
        assertEq(token.balanceOf(notOwner), 100 ether);
        assertEq(token.balanceOf(vault), 900 ether);
        console.log("Transfer assertions passed");
    }

    function testPauseBlocksTransfer() public {
        console.log("=== Pause Blocks Transfer ===");
        accessManager.pause();
        vm.prank(vault);
        vm.expectRevert("Contract is paused");
        token.transfer(notOwner, 1 ether);
        console.log("Pause assertion passed");
    }

    function testOnlyOwnerCanSetPropertyURI() public {
        console.log("=== Only Owner Can Set Property URI ===");
        vm.prank(vault);
        token.setPropertyURI("ipfs://new-uri");
        assertEq(token.propertyURI(), "ipfs://new-uri");
        console.log("Owner updated URI");

        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        token.setPropertyURI("ipfs://fail-uri");
        console.log("Non-owner cannot update URI");
    }
}
