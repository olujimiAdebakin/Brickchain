// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IEscrow
/// @notice Interface for Escrow contract handling property deposits in stablecoins
interface IEscrow {
    /// @notice Emitted when an investor deposits stablecoin for a property
    event DepositReceived(
        uint256 indexed propertyId, address indexed investor, address indexed stablecoin, uint256 amount
    );

    /// @notice Emitted when admin updates stablecoin acceptance
    event StablecoinStatusChanged(address indexed token, bool accepted);

    /// @notice Emitted when investor is refunded
    event RefundIssued(
        uint256 indexed propertyId, address indexed investor, address indexed stablecoin, uint256 amount
    );

    /// @notice Emitted when funds are withdrawn to a recipient
    event WithdrawToExecuted(
        uint256 indexed propertyId,
        address indexed investor,
        address indexed recipient,
        address stablecoin,
        uint256 amount
    );

    /// @notice Emitted when a property is canceled
    event PropertyCanceled(uint256 indexed propertyId);

    /// @notice Emitted when a VaultManager is updated
    event VaultManagerUpdated(address indexed manager, bool allowed);

    function setStablecoinStatus(address token, bool accepted) external;
    function setStablecoinStatusByBatch(address[] calldata tokens, bool[] calldata accepted) external;
    function deposit(uint256 propertyId, address stablecoin, uint256 amount) external;
    function getDeposit(address investor, uint256 propertyId, address stablecoin) external view returns (uint256);
    function isStablecoinAccepted(address token) external view returns (bool);
    function withdrawTo(uint256 propertyId, address investor, address stablecoin, uint256 amount, address recipient) external;
    function updateVaultManager(address manager, bool allowed) external;
}