// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ITokenFactory
/// @notice Interface for deploying property token contracts
interface ITokenFactory {
    /// @notice Emitted when a new token is created
    /// @param tokenAddress The deployed token contract address
    /// @param name Display name of the token
    /// @param symbol Display symbol
    /// @param supply Total supply
    /// @param tokenName Internal ERC20 name
    /// @param tokenSymbol Internal ERC20 symbol
    /// @param owner Owner (registry)
    /// @param kycManager Address of KYC Manager
    /// @param vault Initial token receiver
    event TokenCreated(
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 supply,
        string tokenName,
        string tokenSymbol,
        address indexed owner,
        address kycManager,
        address vault
    );

    /// @notice Deploys a new property token
    /// @dev Can only be called by Registry
    /// @param name Display name for UI
    /// @param symbol Display symbol (short)
    /// @param totalSupply Number of tokens to mint (in wei)
    /// @param tokenName ERC20 name
    /// @param tokenSymbol ERC20 symbol
    /// @param propertyURI Metadata URI
    /// @param kycManager Address of KYC Manager
    /// @param owner Owner of the contract (Registry)
    /// @param vault Receiver of minted tokens
    /// @return tokenAddress Deployed token contract
    function createToken(
        string calldata name,
        string calldata symbol,
        uint256 totalSupply,
        string calldata tokenName,
        string calldata tokenSymbol,
        string calldata propertyURI,
        address kycManager,
        address owner,
        address vault
    ) external returns (address tokenAddress);
}
