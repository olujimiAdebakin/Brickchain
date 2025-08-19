// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessManager} from "../access/AccessManager.sol"; // Centralized role-based access control
import {IEscrow} from "../interfaces/IEscrow.sol"; //  Interface for interacting with the Escrow contract
import {Vault} from "../vault/Vault.sol"; // Vault contract for token sale and distribution
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 token standard interface
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; //Safer token transfers

/// @title VaultManager
/// @notice  Coordinates investment settlement by routing escrowed funds to realtors and distributing tokens via Vault
/// @dev Enforces strict role checks and transparent, auditable execution flow
contract VaultManager is AccessManager {
    using SafeERC20 for IERC20;

    IEscrow public escrow; //  Escrow contract holding investor stablecoin deposits
    Vault public vault; // Vault contract holding property tokens and managing distribution

    /// @notice Emitted when escrowed stablecoin is withdrawn to a realtor
    event WithdrawProcessed(
        uint256 indexed propertyId, address indexed stablecoin, uint256 amount, address indexed recipient
    );

    /// @notice Emitted after successful end-to-end investment flow execution
    event InvestmentFinalized(
        uint256 indexed propertyId,
        address indexed stablecoin,
        uint256 amount,
        address indexed investor,
        address realtor
    );

    /// @notice Sets the admin and core contract dependencies
    /// @param _admin Admin address with elevated permissions
    /// @param _escrow Address of deployed Escrow contract
    /// @param _vault Address of deployed Vault contract
    constructor(address _admin, address _escrow, address _vault) AccessManager(_admin) {
        require(_escrow != address(0) && _vault != address(0), "Invalid dependency");
        escrow = IEscrow(_escrow);
        vault = Vault(_vault);
    }

    /// @notice Settles investment by moving escrowed funds to realtor and property tokens to investor
    /// @dev Must be called by ADMIN to ensure trusted execution
    /// @param propertyId Property identifier
    /// @param stablecoin Address of stablecoin used in escrow deposit
    /// @param investor Investor address receiving property tokens
    /// @param realtor Realtor address receiving stablecoin funds
    function finalizeInvestment(uint256 propertyId, address stablecoin, address investor, address realtor)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(investor != address(0), "Invalid investor");
        require(realtor != address(0), "Invalid realtor");
        require(stablecoin != address(0), "Invalid stablecoin");

        // Step 1: Pull escrowed stablecoin amount
        uint256 amount = escrow.getDeposit(investor, propertyId, stablecoin);
        require(amount > 0, "No escrowed amount");

        // Step 2: Move stablecoin from Escrow to realtor
        escrow.withdrawTo(propertyId, investor, stablecoin, amount, realtor);
        emit WithdrawProcessed(propertyId, stablecoin, amount, realtor);

        // Step 3: Send property tokens from Vault to investor
        vault.adminInvest(propertyId, investor, amount, realtor);

        emit InvestmentFinalized(propertyId, stablecoin, amount, investor, realtor);
    }

    /// @notice Admin function to update the escrow contract (upgradeable architecture)
    /// @param _escrow Address of new Escrow contract
    function updateEscrow(address _escrow) external onlyRole(ADMIN_ROLE) {
        require(_escrow != address(0), "Invalid escrow address");
        escrow = IEscrow(_escrow);
    }

    /// @notice Admin function to update the vault contract (upgradeable architecture)
    /// @param _vault Address of new Vault contract
    function updateVault(address _vault) external onlyRole(ADMIN_ROLE) {
        require(_vault != address(0), "Invalid vault address");
        vault = Vault(_vault);
    }
}
