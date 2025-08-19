// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {VaultManager} from "../src/vault/VaultManager.sol";
import {Vault} from "../src/vault/Vault.sol";
import {Escrow} from "../src/escrow/Escrow.sol";
import {MockStablecoin} from "./mocks/MockStablecoin.sol";
import {MockKYCManager} from "./mocks/MockKYCManager.sol";
import {IEscrow} from "../src/interfaces/IEscrow.sol";

// Custom error from AccessControl
error AccessControlUnauthorizedAccount(address account, bytes32 role);

/// @title VaultManagerTest
/// @notice Integration and unit tests for VaultManager, Vault, and Escrow contracts
contract VaultManagerTest is Test {
    VaultManager public manager;
    Vault public vault;
    Escrow public escrow;
    MockStablecoin public stablecoin;
    MockStablecoin public propertyToken;
    MockKYCManager public kyc;

    address admin = address(0xA11);
    address investor = address(0xBEEF);
    address realtor = address(0xCAFE);
    address registry = address(0xDEAD);

    uint256 propertyId = 1;

    // Declare the relevant events --- copied from actual contracts
    event InvestmentFinalized(
        uint256 indexed propertyId,
        address indexed stablecoin,
        uint256 amount,
        address indexed investor,
        address realtor
    );

    event WithdrawProcessed(
        uint256 indexed propertyId,
        address indexed stablecoin,
        uint256 amount,
        address indexed recipient
    );

    event WithdrawToExecuted(
        uint256 indexed propertyId,
        address indexed investor,
        address indexed recipient,
        address stablecoin,
        uint256 amount
    );

    /// @dev Sets up the test environment before each test
    function setUp() public {
        vm.startPrank(admin);

        // Deploy and mint stablecoin to investor
        stablecoin = new MockStablecoin("BRICK Stable", "BRSD");
        stablecoin.mint(investor, 10000 * 1e6); // 10,000 USDC with 6 decimals
        console.log("Minted 10,000 USDC to investor");

        // Deploy KYC manager and Escrow
        kyc = new MockKYCManager();
        escrow = new Escrow(admin, address(kyc));
        escrow.setStablecoinStatus(address(stablecoin), true);
        console.log("Escrow and KYC set up");

        // Deploy property token (acts as property share)
        propertyToken = new MockStablecoin("BRICK Property", "BRPT");

        // Deploy Vault and VaultManager
        vault = new Vault(admin, address(kyc), registry, address(stablecoin));
        manager = new VaultManager(admin, address(escrow), address(vault));
        console.log("Vault and VaultManager deployed");

        // Set permissions and KYC
        escrow.updateVaultManager(address(manager), true);
        vault.grantRole(vault.ADMIN_ROLE(), address(manager));
        kyc.setKYCApproved(investor, true);
        console.log("Permissions and KYC set");

        vm.stopPrank();

        // Register property token in the vault as registry
        vm.startPrank(registry);
        vault.registerToken(propertyId, address(propertyToken), 1e6, 1_000_000 ether); // 1 BRPT = $1
        vm.stopPrank();
        console.log("Property token registered in vault");

        // Mint property tokens to the vault for distribution
        propertyToken.mint(address(vault), 1000 * 1e18); // Mint 1000 tokens to the vault
        console.log("Minted 1000 property tokens to vault");
    }

    /// @notice Helper to deposit stablecoin from investor to escrow
    /// @dev Mints and deposits `_amount` stablecoin for `_propertyId`
    function depositFromInvestorToEscrow(uint256 _propertyId, uint256 _amount) internal {
        vm.startPrank(investor);
        stablecoin.mint(investor, _amount);
        stablecoin.approve(address(escrow), _amount);
        escrow.deposit(_propertyId, address(stablecoin), _amount);
        vm.stopPrank();

        uint256 escrowBal = stablecoin.balanceOf(address(escrow));
        console.log("Escrow stablecoin balance:", escrowBal);
        assertEq(escrowBal, _amount, "Escrow should hold the investor's deposit");
    }

    /// @notice Integration test for finalizing an investment
    /// @dev Checks event emission and vault balance after finalization
    function testFinalizeInvestment_Integration() public {
        uint256 depositAmount = 1000 * 1e6; // 1000 USDC with 6 decimals

        depositFromInvestorToEscrow(propertyId, depositAmount);

        vm.expectEmit(true, true, true, false);
        emit WithdrawToExecuted(
            propertyId,
            investor,
            realtor,
            address(stablecoin),
            depositAmount
        );

        vm.expectEmit(true, true, false, true);
        emit WithdrawProcessed(
            propertyId,
            address(stablecoin),
            depositAmount,
            realtor
        );

        vm.expectEmit(true, true, false, true);
        emit InvestmentFinalized(
            propertyId,
            address(stablecoin),
            depositAmount,
            investor,
            realtor
        );

        vm.prank(admin);
        manager.finalizeInvestment(propertyId, address(stablecoin), investor, realtor);

        uint256 vaultBalance = stablecoin.balanceOf(address(vault));
        console.log("Vault stablecoin balance after finalization:", vaultBalance);
        assertEq(vaultBalance, 0, "Vault should not hold stablecoins after finalization");
    }

    /// @notice Test withdrawing stablecoin from the vault
    /// @dev Checks that admin receives correct amount after withdrawal
    function testWithdrawStablecoin() public {
        uint256 mintAmount = 500 * 1e6; // 500 USDC

        vm.prank(admin);
        stablecoin.mint(address(vault), mintAmount);

        uint256 before = stablecoin.balanceOf(admin);
        vm.prank(admin);
        vault.withdrawStablecoin(admin);
        uint256 afterBal = stablecoin.balanceOf(admin);

        console.log("Withdrawn amount:", afterBal - before);
        assertEq(afterBal - before, mintAmount, "Vault stablecoin not withdrawn correctly");
    }

    /// @notice Test that only admin can finalize investments
    /// @dev Expects revert if called by non-admin
    function test_RevertIfCalledByNonAdmin() public {
        vm.expectRevert(
            abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, investor, manager.ADMIN_ROLE())
        );

        vm.prank(investor);
        manager.finalizeInvestment(propertyId, address(stablecoin), investor, realtor);
    }

    /// @notice Test reverts for zero address inputs
    /// @dev Expects revert for invalid investor, realtor, or stablecoin address
    function test_RevertIfZeroAddressInputs() public {
        vm.startPrank(admin);

        vm.expectRevert("Invalid investor");
        manager.finalizeInvestment(propertyId, address(stablecoin), address(0), realtor);

        vm.expectRevert("Invalid realtor");
        manager.finalizeInvestment(propertyId, address(stablecoin), investor, address(0));

        vm.expectRevert("Invalid stablecoin");
        manager.finalizeInvestment(propertyId, address(0), investor, realtor);

        vm.stopPrank();
    }

    /// @notice Test revert if vault is inactive
    /// @dev Pauses vault and expects revert on finalizeInvestment
    function test_RevertIfVaultInactive() public {
        vm.prank(admin);
        vault.pauseVault(propertyId);

        uint256 depositAmount = 100 * 1e6;
        depositFromInvestorToEscrow(propertyId, depositAmount);

        vm.expectRevert("Vault inactive");
        vm.prank(admin);
        manager.finalizeInvestment(propertyId, address(stablecoin), investor, realtor);
    }

    /// @notice Test revert if escrow is empty
    /// @dev Expects revert when no escrowed amount exists
    function test_RevertIfEscrowEmpty() public {
        vm.expectRevert("No escrowed amount");
        vm.prank(admin);
        manager.finalizeInvestment(propertyId, address(stablecoin), investor, realtor);
    }

    /// @notice Test revert if token overflow occurs
    /// @dev Expects revert when deposit exceeds property token supply
    function test_RevertIfTokenOverflow() public {
        uint256 limitedPropertyId = 999;

        vm.startPrank(registry);
        vault.registerToken(limitedPropertyId, address(stablecoin), 1e6, 100 ether);
        vm.stopPrank();

        uint256 depositAmount = 1000 * 1e6;
        depositFromInvestorToEscrow(limitedPropertyId, depositAmount);

        vm.expectRevert("Invalid token amount");
        vm.prank(admin);
        manager.finalizeInvestment(limitedPropertyId, address(stablecoin), investor, realtor);
    }

    /// @notice Test revert if VaultManager is unauthorized in Escrow
    /// @dev Expects revert when VaultManager is not authorized
    function test_RevertIfEscrowUnauthorized() public {
        vm.prank(admin);
        escrow.updateVaultManager(address(manager), false);

        uint256 depositAmount = 100 * 1e6;
        depositFromInvestorToEscrow(propertyId, depositAmount);

        vm.expectRevert("Unauthorized VaultManager");
        vm.prank(admin);
        manager.finalizeInvestment(propertyId, address(stablecoin), investor, realtor);
    }

    /// @notice Test that admin can withdraw vault balance
    /// @dev Checks admin's balance before and after withdrawal
    function test_AdminCanWithdrawVaultBalance() public {
        uint256 mintAmount = 500 * 1e6;

        vm.prank(admin);
        stablecoin.mint(address(vault), mintAmount);

        uint256 before = stablecoin.balanceOf(admin);
        vm.prank(admin);
        vault.withdrawStablecoin(admin);
        uint256 afterBal = stablecoin.balanceOf(admin);

        console.log("Admin balance before:", before);
        console.log("Admin balance after:", afterBal);
        assertEq(afterBal - before, mintAmount, "Vault stablecoin not withdrawn correctly");
    }
}