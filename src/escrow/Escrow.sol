// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessManager} from "../access/AccessManager.sol"; //  Centralized role and permission control
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Interface for ERC20 tokens
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Prevents faulty ERC20 transfers
import {IKYCManager} from "../interfaces/IKYCManager.sol"; // Interface to KYC verification contract
import {IEscrow} from "../interfaces/IEscrow.sol"; // Interface for Escrow contract handling deposits

/// @title Escrow
/// @notice Accepts multiple stablecoins from KYC-verified investors for property deposits
/// @dev Enforces role-based access control, KYC verification, and ERC20 transfer safety
contract Escrow is AccessManager, IEscrow {
    using SafeERC20 for IERC20;

    /// @notice Mapping to track accepted stablecoins
    mapping(address => bool) public acceptedStablecoins;

    /// @notice KYC manager contract to verify investor eligibility
    IKYCManager public kycManager;

    /// @notice Mapping: propertyId => investor => stablecoin => deposit amount
    mapping(uint256 => mapping(address => mapping(address => uint256))) public deposits;

    /// @notice Mapping: propertyId => investor => stablecoin => deposit timestamp
    mapping(uint256 => mapping(address => mapping(address => uint256))) public depositTimestamps;

    /// @notice Property cancellation state
    mapping(uint256 => bool) public isCanceled;

    /// @notice Whitelisted VaultManager contracts
    mapping(address => bool) public isVaultManager;

    /// @notice Deposit expiration period (e.g. 30 days)
    uint256 public constant EXPIRY_PERIOD = 30 days;

    /// @notice Constructor to initialize roles and external KYC manager
    /// @param _admin Address granted the ADMIN_ROLE
    /// @param _kycManager External KYC manager contract
    constructor(address _admin, address _kycManager) AccessManager(_admin) {
        kycManager = IKYCManager(_kycManager);
    }

    /// @notice Restricts access to only KYC-approved investors
    modifier onlyKYCInvestor() {
        require(kycManager.isKYCApproved(msg.sender), "Not KYC approved");
        _;
    }

    /// @notice Restricts access to whitelisted VaultManager contracts
    modifier onlyVaultManager() {
        require(isVaultManager[msg.sender], "Unauthorized VaultManager");
        _;
    }

    /// @notice Admin sets acceptance status of a stablecoin (e.g., USDC, USDT, cNGN)
    function setStablecoinStatus(address token, bool accepted) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Invalid token address");
        require(acceptedStablecoins[token] != accepted, "No status change");
        acceptedStablecoins[token] = accepted;
        emit StablecoinStatusChanged(token, accepted);
    }

    /// @notice Admin can batch update acceptance status of multiple stablecoins
    function setStablecoinStatusByBatch(address[] calldata tokens, bool[] calldata accepted)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(tokens.length == accepted.length, "Length mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            bool isAccepted = accepted[i];

            require(token != address(0), "Invalid token address");
            require(acceptedStablecoins[token] != isAccepted, "No status change");

            acceptedStablecoins[token] = isAccepted;
            emit StablecoinStatusChanged(token, isAccepted);
        }
    }

    /// @notice Allows KYC-verified investors to deposit into escrow for a property
    function deposit(uint256 propertyId, address stablecoin, uint256 amount) external onlyKYCInvestor nonReentrant {
        require(acceptedStablecoins[stablecoin], "Unsupported stablecoin");
        require(amount > 0, "Amount must be > 0");

        deposits[propertyId][msg.sender][stablecoin] += amount;
        depositTimestamps[propertyId][msg.sender][stablecoin] = block.timestamp;

        IERC20(stablecoin).safeTransferFrom(msg.sender, address(this), amount);

        emit DepositReceived(propertyId, msg.sender, stablecoin, amount);
    }

    /// @notice Admin withdraws deposited funds to a specified recipient (e.g. realtor)
    function withdrawTo(uint256 propertyId, address investor, address stablecoin, uint256 amount, address recipient)
        external
        onlyVaultManager
    {
        require(deposits[propertyId][investor][stablecoin] >= amount, "Insufficient deposit");

        deposits[propertyId][investor][stablecoin] -= amount;
        IERC20(stablecoin).safeTransfer(recipient, amount);

        emit WithdrawToExecuted(propertyId, investor, recipient, stablecoin, amount);
    }

    /// @notice Allows an investor to refund their deposit if the project is canceled
    function refund(uint256 propertyId, address stablecoin) external nonReentrant {
        require(isCanceled[propertyId], "Property not canceled");
        uint256 amount = deposits[propertyId][msg.sender][stablecoin];
        require(amount > 0, "Nothing to refund");

        deposits[propertyId][msg.sender][stablecoin] = 0;
        IERC20(stablecoin).safeTransfer(msg.sender, amount);

        emit RefundIssued(propertyId, msg.sender, stablecoin, amount);
    }

    /// @notice Allows admin to cancel a property project
    function cancelProperty(uint256 propertyId) external onlyRole(ADMIN_ROLE) {
        isCanceled[propertyId] = true;
        emit PropertyCanceled(propertyId);
    }

    /// @notice Admin configures which addresses are approved VaultManagers
    function updateVaultManager(address manager, bool allowed) external onlyRole(ADMIN_ROLE) {
        require(manager != address(0), "Invalid address");
        isVaultManager[manager] = allowed;
        emit VaultManagerUpdated(manager, allowed);
    }

    /// @notice Admin can reclaim funds if deposits have expired
    function reclaimExpiredDeposit(uint256 propertyId, address investor, address stablecoin, address recipient)
        external
        onlyRole(ADMIN_ROLE)
    {
        uint256 timestamp = depositTimestamps[propertyId][investor][stablecoin];
        require(timestamp > 0 && block.timestamp > timestamp + EXPIRY_PERIOD, "Not expired");

        uint256 amount = deposits[propertyId][investor][stablecoin];
        require(amount > 0, "Nothing to reclaim");

        deposits[propertyId][investor][stablecoin] = 0;
        IERC20(stablecoin).safeTransfer(recipient, amount);
    }

    function getDeposit(address investor, uint256 propertyId, address stablecoin) external view returns (uint256) {
        return deposits[propertyId][investor][stablecoin];
    }

    function isStablecoinAccepted(address token) external view returns (bool) {
        return acceptedStablecoins[token];
    }
}
