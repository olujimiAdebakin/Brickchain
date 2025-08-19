// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";
// import {VaultManager} from "../src/vault/VaultManager.sol";
// import {Vault} from "../src/vault/Vault.sol";
// import {Escrow} from "../src/escrow/Escrow.sol";
// import {MockStablecoin} from "./mocks/MockStablecoin.sol";
// import {MockKYCManager} from "./mocks/MockKYCManager.sol";
// import {Registry} from "../src/registry/Registry.sol";
// import {PropertyToken} from "../src/tokens/PropertyToken.sol";
// import {TokenFactory} from "../src/factory/TokenFactory.sol";
// import {AccessManager} from "../src/access/AccessManager.sol";

// contract VaultManagerIntegrationTest is Test {
//     VaultManager public manager;
//     Vault public vault;
//     Escrow public escrow;
//     MockStablecoin public stablecoin;
//     MockKYCManager public kyc;
//     Registry public registry;
//     TokenFactory public tokenFactory;
//     PropertyToken public propertyToken;
//     AccessManager public accessManager;

//     address admin = address(0xA11);
//     address investor = address(0xBEEF);
//     address realtor = address(0xCAFE);
//     address feeRecipient = address(0x1234);
//     address priceFeed = address(0xBEEF1);

//     uint256 propertyId;

//     // function setUp() public {
//     //     vm.startPrank(admin);

//     //     stablecoin = new MockStablecoin("BRICK Stable", "BRSD");
//     //     stablecoin.mint(investor, 10000 * 1e6);

//     //     kyc = new MockKYCManager();
//     //     escrow = new Escrow(admin, address(kyc));
//     //     escrow.setStablecoinStatus(address(stablecoin), true);

//     //     tokenFactory = new TokenFactory(registry);
//     //     vault = new Vault(admin, address(kyc), address(0), address(stablecoin));
//     //     registry = new Registry(admin, address(tokenFactory), 0, feeRecipient, priceFeed, address(kyc), address(vault));
//     //     manager = new VaultManager(admin, address(escrow), address(vault));

//     //     escrow.updateVaultManager(address(manager), true);
//     //     vault.grantRole(vault.ADMIN_ROLE(), address(manager));

//     //     kyc.setKYCApproved(investor, true);
//     //     registry.grantRealtorRole(realtor);
//     //     kyc.setKYCApproved(realtor, true);

//     //     vault.updateRegistry(address(registry));

//     //     vm.deal(realtor, 10 ether);
//     //     vm.stopPrank();

//     //     // Realtor lists a property
//     //     vm.startPrank(realtor);
//     //     registry.registerProperty{
//     //         value: 1 ether
//     //     }(
//     //         "Test Property",
//     //         "Location",
//     //         100_000,
//     //         "A great property",
//     //         10,
//     //         "ipfs://property"
//     //     );
//     //     vm.stopPrank();

//     //     propertyId = 1;
//     // }

//    function setUp() public {
//     vm.startPrank(admin);

//     stablecoin = new MockStablecoin("BRICK Stable", "BRSD");
//     stablecoin.mint(investor, 10000 * 1e6);

//     kyc = new MockKYCManager();
//     escrow = new Escrow(admin, address(kyc));
//     escrow.setStablecoinStatus(address(stablecoin), true);

//     // 1. Deploy Registry with placeholders for tokenFactory and vault
//     registry = new Registry(
//         admin,
//         address(0), // tokenFactory placeholder
//         0,
//         feeRecipient,
//         priceFeed,
//         address(kyc),
//         address(0) // vault placeholder
//     );

//     // 2. Deploy TokenFactory and Vault with registry address
//     tokenFactory = new TokenFactory(address(registry), address(accessManager));
//     vault = new Vault(admin, address(kyc), address(registry), address(stablecoin));

//     // 3. Update Registry with correct tokenFactory and vault addresses
//     registry.setTokenFactory(address(tokenFactory));
//     registry.setVault(address(vault));

//     // 4. Continue as before
//     manager = new VaultManager(admin, address(escrow), address(vault));
//     escrow.updateVaultManager(address(manager), true);
//     vault.grantRole(vault.ADMIN_ROLE(), address(manager));
//     kyc.setKYCApproved(investor, true);
//     registry.grantRealtorRole(realtor);
//     kyc.setKYCApproved(realtor, true);
//     vm.deal(realtor, 10 ether);
//     vm.stopPrank();

//     // Realtor lists a property
//     vm.startPrank(realtor);
//     registry.registerProperty{value: 1 ether}(
//         "Test Property",
//         "Location",
//         100_000,
//         "A great property",
//         10,
//         "ipfs://property"
//     );
//     vm.stopPrank();

//     propertyId = 1;
// }


//     function testFinalizeInvestmentFromEndToEnd() public {
//         uint256 depositAmount = 1000 * 1e6;

//         // Investor deposits stablecoin to escrow
//         vm.startPrank(investor);
//         stablecoin.approve(address(escrow), depositAmount);
//         escrow.deposit(propertyId, address(stablecoin), depositAmount);
//         vm.stopPrank();

//         // Finalize investment
//         address tokenAddr = registry.getProperty(propertyId).tokenAddress;
//         propertyToken = PropertyToken(tokenAddr);

//         uint256 vaultTokenBalBefore = propertyToken.balanceOf(address(vault));

//         vm.prank(admin);
//         manager.finalizeInvestment(propertyId, address(stablecoin), investor, realtor);

//         uint256 vaultTokenBalAfter = propertyToken.balanceOf(address(vault));
//         uint256 investorBal = propertyToken.balanceOf(investor);

//         assertGt(investorBal, 0);
//         assertLt(vaultTokenBalAfter, vaultTokenBalBefore);
//         assertEq(stablecoin.balanceOf(address(vault)), 0);
//     }

//     function testRevertsIfNotKYCApproved() public {
//         address unverified = address(0xBAD);
//         stablecoin.mint(unverified, 1000 * 1e6);
//         vm.startPrank(unverified);
//         stablecoin.approve(address(escrow), 1000 * 1e6);
//         vm.expectRevert("KYC not approved");
//         escrow.deposit(propertyId, address(stablecoin), 1000 * 1e6);
//         vm.stopPrank();
//     }

//     function testRevertsIfBlacklisted() public {
//         kyc.setBlacklisted(investor, true);
//         vm.startPrank(investor);
//         stablecoin.approve(address(escrow), 1000 * 1e6);
//         vm.expectRevert("Blacklisted");
//         escrow.deposit(propertyId, address(stablecoin), 1000 * 1e6);
//         vm.stopPrank();
//     }

//     function testInvestmentOverflowProtection() public {
//         uint256 bigAmount = type(uint256).max;
//         vm.startPrank(investor);
//         stablecoin.approve(address(escrow), bigAmount);
//         vm.expectRevert(); // expect overflow or custom revert
//         escrow.deposit(propertyId, address(stablecoin), bigAmount);
//         vm.stopPrank();
//     }

//     function testListingFeePaidInETHSimulated() public {
//         // Simulate listing with priceFeed and correct ETH
//         vm.startPrank(realtor);
//         registry.registerProperty{
//             value: 1 ether
//         }(
//             "Test ETH Property",
//             "Location",
//             100_000,
//             "Another property",
//             10,
//             "ipfs://eth-property"
//         );
//         vm.stopPrank();
//     }
// }
