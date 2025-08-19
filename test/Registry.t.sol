// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/StdUtils.sol";

import {Registry} from "src/Registry/Registry.sol";
import {RegistryStorage} from "src/Registry/RegistryStorage.sol";
import {MockTokenFactory} from "test/mocks/MockTokenFactory.sol";
import {MockKYCManager} from "test/mocks/MockKYCManager.sol";
import {MockPriceFeed} from "test/mocks/MockPriceFeed.sol";

contract RegistryTest is Test {
    Registry public registry;
    MockTokenFactory public tokenFactory;
    MockKYCManager public kycManager;
    MockPriceFeed public priceFeed;

    address admin = address(0xA11);
    address realtor = address(0xB22);
    address vault = address(0xC33);
    address feeRecipient = address(0xD44);

    function setUp() public {
        console.log("=== Setting up Registry Test ===");
        tokenFactory = new MockTokenFactory();
        kycManager = new MockKYCManager();
        priceFeed = new MockPriceFeed();

        registry = new Registry(
            admin, address(tokenFactory), 0.15 ether, feeRecipient, address(priceFeed), address(kycManager), vault
        );

        vm.startPrank(admin);
        registry.grantRealtorRole(realtor);
        kycManager.setKYCApproved(realtor, true);
        vm.stopPrank();

        console.log("Registry deployed at:", address(registry));
        console.log("Realtor role granted and KYC approved");
        console.log("=== Setup Complete ===\n");
    }

    function testRegisterPropertySuccess() public {
        console.log("=== Testing Property Registration Success ===");
        vm.startPrank(realtor);

        // --- Fee calculation using mock price feed ---
        uint256 totalValue = 200_000;
        uint256 pricePerToken = 20;
        uint256 listingFeeUSD = (totalValue * 15) / 100; // 30,000
        uint256 ethPrice = 2000e8; // $2,000 with 8 decimals
        uint256 expectedFee = (listingFeeUSD * 1e18 * 1e8) / ethPrice; // 15 ETH
        priceFeed.setRate(ethPrice);

        // --- Property details ---
        string memory name = "Ocean View";
        string memory location = "Lagos";
        string memory description = "Luxury beachfront apartment";
        string memory uri = "ipfs://metadata";

        // --- Logging ---
        console.log("Property details:");
        console.log("Total value (USD):", totalValue);
        console.log("Price per token (USD):", pricePerToken);
        console.log("Listing fee (USD):", listingFeeUSD);
        console.log("Listing fee (ETH):", expectedFee);

        vm.deal(realtor, expectedFee);
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        console.log("Fee recipient balance before registration:", feeRecipientBalanceBefore);
        console.log("Realtor ETH balance before registration:", realtor.balance);

        // --- Register property ---
        registry.registerProperty{value: expectedFee}(name, location, totalValue, description, pricePerToken, uri);

        console.log("Property registered successfully!");
        console.log("Realtor ETH balance after registration:", realtor.balance);

        RegistryStorage.Property memory prop = registry.getProperty(1);
        console.log("Retrieved property details:");
        console.log("Name:", prop.name);
        console.log("Total value:", prop.totalValue);
        console.log("Token supply:", prop.tokenSupply);
        console.log("Realtor:", prop.realtor);
        console.log("Is active:", prop.isActive);
        console.log("Metadata URI:", prop.metadataURI);
        console.log("Vault:", prop.vault);

        uint256 feeRecipientBalanceAfter = feeRecipient.balance;
        console.log("Fee recipient balance after registration:", feeRecipientBalanceAfter);

        // --- Assertions ---
        assertEq(prop.name, name);
        assertEq(prop.totalValue, totalValue);
        assertEq(prop.tokenSupply, (totalValue * 1e18) / pricePerToken);
        assertEq(prop.realtor, realtor);
        assertTrue(prop.isActive);
        assertEq(prop.metadataURI, uri);
        assertEq(prop.vault, vault);
        assertEq(
            feeRecipientBalanceAfter - feeRecipientBalanceBefore, expectedFee, "Listing fee not transferred correctly"
        );

        console.log("All assertions passed!");
        vm.stopPrank();
    }

    function test_RevertWhen_InvalidKYC() public {
        console.log("=== Testing Invalid KYC Failure ===");
        address badRealtor = address(0xBad);

        vm.startPrank(admin);
        registry.grantRealtorRole(badRealtor);
        vm.stopPrank();

        vm.prank(badRealtor);
        vm.expectRevert();
        registry.registerProperty("Test", "Loc", 100000, "Desc", 10, "ipfs://uri");
        console.log("Test passed: Transaction reverted as expected!");
    }

    function test_RevertWhen_InvalidURI() public {
        console.log("=== Testing Invalid URI Failure ===");
        vm.prank(realtor);
        vm.expectRevert();
        registry.registerProperty("Test", "Loc", 100000, "Desc", 10, "invalid");
        console.log("Test passed: Transaction reverted as expected!");
    }

    function test_RevertWhen_InsufficientListingFee() public {
        console.log("=== Testing Insufficient Listing Fee Failure ===");
        vm.startPrank(realtor);

        // --- Fee calculation ---
        uint256 totalValue = 200_000;
        uint256 pricePerToken = 20;
        uint256 listingFeeUSD = (totalValue * 15) / 100;
        uint256 ethPrice = 2000e8;
        uint256 requiredFee = (listingFeeUSD * 1e18 * 1e8) / ethPrice;
        uint256 providedFee = requiredFee - 1; // less than required
        priceFeed.setRate(ethPrice);
        vm.deal(realtor, providedFee);

        vm.expectRevert("Insufficient listing fee");
        registry.registerProperty{value: providedFee}("Test", "Loc", totalValue, "Desc", pricePerToken, "ipfs://uri");
        vm.stopPrank();
    }

    function testTokenPriceValidation() public {
        console.log("=== Testing Token Price Validation ===");
        vm.startPrank(realtor);

        uint256 ethPrice = 2000e8;
        priceFeed.setRate(ethPrice);

        // < $50k, price per token must be $5
        uint256 fee1 = ((40_000 * 15) / 100) * 1e18 * 1e8 / ethPrice;
        vm.deal(realtor, fee1);
        vm.expectRevert("Token price must be $5 for properties < $50k");
        registry.registerProperty{value: fee1}("Test", "Loc", 40_000, "Desc", 10, "ipfs://uri");

        // $50k-$150k, price per token must be $10
        uint256 fee2 = ((100_000 * 15) / 100) * 1e18 * 1e8 / ethPrice;
        vm.deal(realtor, fee2);
        vm.expectRevert("Token price must be $10 for $50k-$150k");
        registry.registerProperty{value: fee2}("Test", "Loc", 100_000, "Desc", 5, "ipfs://uri");

        // > $150k, price per token must be $20
        uint256 fee3 = ((200_000 * 15) / 100) * 1e18 * 1e8 / ethPrice;
        vm.deal(realtor, fee3);
        vm.expectRevert("Token price must be $20 for properties > $150k");
        registry.registerProperty{value: fee3}("Test", "Loc", 200_000, "Desc", 5, "ipfs://uri");

        vm.stopPrank();
    }

    function testPropertyStatusToggle() public {
        console.log("=== Testing Property Status Toggle ===");
        vm.startPrank(realtor);

        // --- Fee calculation ---
        uint256 totalValue = 200_000;
        uint256 pricePerToken = 20;
        uint256 listingFeeUSD = (totalValue * 15) / 100;
        uint256 ethPrice = 2000e8;
        uint256 expectedFee = (listingFeeUSD * 1e18 * 1e8) / ethPrice;
        priceFeed.setRate(ethPrice);
        vm.deal(realtor, expectedFee);

        // --- Register property ---
        registry.registerProperty{value: expectedFee}("Test", "Loc", totalValue, "Desc", pricePerToken, "ipfs://uri");

        // --- Toggle status ---
        registry.updatePropertyStatus(1, false);
        RegistryStorage.Property memory prop = registry.getProperty(1);
        console.log("Property status after toggle:", prop.isActive);
        assertFalse(prop.isActive);

        vm.stopPrank();
    }

    function testAdminDeactivate() public {
        console.log("=== Testing Admin Deactivate Property ===");
        vm.startPrank(realtor);

        // --- Fee calculation ---
        uint256 totalValue = 200_000;
        uint256 pricePerToken = 20;
        uint256 listingFeeUSD = (totalValue * 15) / 100;
        uint256 ethPrice = 2000e8;
        uint256 expectedFee = (listingFeeUSD * 1e18 * 1e8) / ethPrice;
        priceFeed.setRate(ethPrice);
        vm.deal(realtor, expectedFee);

        // --- Register property ---
        registry.registerProperty{value: expectedFee}("Test", "Loc", totalValue, "Desc", pricePerToken, "ipfs://uri");
        vm.stopPrank();

        // --- Admin deactivates property ---
        vm.prank(admin);
        registry.deactivateProperty(1);

        RegistryStorage.Property memory prop = registry.getProperty(1);
        assertFalse(prop.isActive);
    }

    function testAdminWithdrawAndUpdate() public {
        console.log("=== Testing Admin Withdraw and Update ===");
        address newFeeRecipient = address(0xFEE);

        // --- Update fee recipient ---
        vm.prank(admin);
        registry.updateFeeRecipient(newFeeRecipient);
        assertEq(registry.feeRecipient(), newFeeRecipient);

        // --- Add ETH to registry and withdraw ---
        uint256 withdrawAmount = 1 ether;
        vm.deal(address(registry), withdrawAmount);

        vm.prank(admin);
        registry.withdraw();

        assertEq(newFeeRecipient.balance, withdrawAmount);
        console.log("Withdraw test passed!");
    }

    function testGetRealtorProperties() public {
        console.log("=== Testing Get Realtor Properties ===");
        vm.startPrank(realtor);

        // --- Fee calculation ---
        uint256 totalValue = 200_000;
        uint256 pricePerToken = 20;
        uint256 listingFeeUSD = (totalValue * 15) / 100;
        uint256 ethPrice = 2000e8;
        uint256 expectedFee = (listingFeeUSD * 1e18 * 1e8) / ethPrice;
        priceFeed.setRate(ethPrice);
        vm.deal(realtor, expectedFee * 2);

        // --- Register two properties ---
        registry.registerProperty{value: expectedFee}(
            "Property A", "Location A", totalValue, "Description A", pricePerToken, "ipfs://uri1"
        );
        registry.registerProperty{value: expectedFee}(
            "Property B", "Location B", totalValue, "Description B", pricePerToken, "ipfs://uri2"
        );

        // --- Fetch and log property IDs ---
        uint256[] memory ids = registry.getPropertiesByRealtor(realtor);
        console.log("Number of properties found:", ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            console.log("Property ID:", ids[i]);
        }

        // --- Assertions ---
        assertEq(ids.length, 2);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);

        vm.stopPrank();
    }
}
