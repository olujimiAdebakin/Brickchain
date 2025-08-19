// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessManager} from "../access/AccessManager.sol"; // Provides RBAC (Role-Based Access Control) mechanism for ADMIN and other roles
import {IKYCManager} from "../interfaces/IKYCManager.sol"; // External interface to validate users' KYC approval status
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 token standard interface
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Wrapper to safely perform ERC20 operations without silent failures

/// @title Vault
/// @notice Manages property token vaults for secure and compliant token distribution
/// @dev Implements access control, investor validation, token pricing, and token sale lifecycle
contract Vault is AccessManager {
    using SafeERC20 for IERC20;

    /// @notice Structure to manage each property's token vault metadata
    struct PropertyVault {
        address token; // ERC20 property token contract address
        uint256 tokenPriceUSD; // Price per token in stablecoin (6 decimals, e.g., USDT/USDC)
        uint256 unsoldTokens; // Total number of unsold property tokens
        bool isActive; // Status indicating if the vault is active (true) or paused (false)
    }

    /// @notice Mapping of propertyId => PropertyVault struct
    mapping(uint256 => PropertyVault) public vaults;

    IKYCManager public kycManager; // Contract for checking whether an address has passed KYC verification
    address public registry; // Registry contract allowed to register new property token vaults
    IERC20 public stablecoin; // Default stablecoin (e.g., USDT or USDC) used for property token purchases

    /// @notice Emitted when a new property token vault is registered
    event PropertyTokenRegistered(uint256 indexed propertyId, address token, uint256 totalSupply);

    /// @notice Emitted when tokens are purchased from a vault
    event TokensPurchased(
        uint256 indexed propertyId, address indexed investor, uint256 tokenAmount, uint256 stablecoinSpent
    );

    /// @notice Emitted when stablecoins are withdrawn from the vault
    event StablecoinWithdrawn(address indexed to, uint256 amount);

    /// @notice Initializes the Vault contract with core system components
    /// @param _admin Address granted ADMIN_ROLE for privileged operations
    /// @param _kycManager KYC validation contract used for identity verification
    /// @param _registry Registry contract allowed to initialize vaults
    /// @param _stablecoin Default accepted stablecoin address (ERC20 compliant)
    constructor(address _admin, address _kycManager, address _registry, address _stablecoin) AccessManager(_admin) {
        kycManager = IKYCManager(_kycManager);
        registry = _registry;
        stablecoin = IERC20(_stablecoin);
    }

    /// @notice Restricts function to only the registry contract
    modifier onlyRegistry() {
        require(msg.sender == registry, "Only Registry");
        _;
    }

    /// @notice Restricts function access to only KYC-verified investors
    modifier onlyKYCInvestor() {
        require(kycManager.isKYCApproved(msg.sender), "Not KYC approved");
        _;
    }

     /// @notice Restricts to only admin or auditor roles
    modifier onlyAdminOrAuditor() override {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = DEFAULT_ADMIN_ROLE;
        roles[1] = AUDITOR_ROLE;
        require(AccessManager.hasAnyRole(msg.sender, roles), "Not admin or auditor");
        _;
    }

 

    function updateRegistry(address _registry) external onlyAdminOrAuditor {
    registry = _registry;
}

    /// @notice Registers a new vault for a specific property
    /// @dev Can only be called by the Registry contract to avoid unauthorized property listings
    /// @param propertyId Unique identifier for the property
    /// @param token Address of the ERC20 property token
    /// @param pricePerTokenUSD Price of one property token in stablecoin (e.g., 1.50 USDT = 1500000 with 6 decimals)
    /// @param supply Initial number of tokens available for purchase
    function registerToken(uint256 propertyId, address token, uint256 pricePerTokenUSD, uint256 supply)
        external
        onlyRegistry
    {
        require(token != address(0), "Invalid token address");
        require(supply > 0, "Supply must be > 0");
        require(pricePerTokenUSD > 0, "Price must be > 0");

        vaults[propertyId] =
            PropertyVault({token: token, tokenPriceUSD: pricePerTokenUSD, unsoldTokens: supply, isActive: true});

        emit PropertyTokenRegistered(propertyId, token, supply);
    }

    /// @notice Admin function to manually allocate tokens to investor and transfer stablecoin to realtor
    /// @dev Useful for escrow settlement or off-chain agreement processing
    /// @param propertyId ID of the property whose vault is targeted
    /// @param investor Address receiving the property tokens
    // / @param stablecoinAddr Address of the stablecoin being transferred
    /// @param stablecoinAmount Amount of stablecoin used for token purchase (6 decimals)
    /// @param realtor Address to receive the stablecoin payment
    function adminInvest(
        uint256 propertyId,
        address investor,
        // address stablecoinAddr,
        uint256 stablecoinAmount,
        address realtor
    ) external virtual onlyRole(ADMIN_ROLE) nonReentrant {
        PropertyVault storage vault = vaults[propertyId];

        require(vault.isActive, "Vault inactive");
        require(stablecoinAmount > 0, "Zero amount");
        require(realtor != address(0), "Invalid realtor address");

        // Compute the number of tokens the investor receives based on stablecoin sent
        uint256 tokenAmount = (stablecoinAmount * 1e18) / vault.tokenPriceUSD;
        require(tokenAmount > 0 && tokenAmount <= vault.unsoldTokens, "Invalid token amount");

        vault.unsoldTokens -= tokenAmount;

        // Transfer stablecoin from VaultManager to realtor and tokens to investor
        // IERC20(stablecoinAddr).safeTransfer(realtor, stablecoinAmount);

        // Transfer property tokens to investor
        IERC20(vault.token).safeTransfer(investor, tokenAmount);

        emit TokensPurchased(propertyId, investor, tokenAmount, stablecoinAmount);
    }

    /// @notice Emergency function to pause property vault sales (admin-only)
    function pauseVault(uint256 propertyId) external onlyRole(ADMIN_ROLE) {
        vaults[propertyId].isActive = false;
    }

    /// @notice Resumes a paused property vault (admin-only)
    function unpauseVault(uint256 propertyId) external onlyRole(ADMIN_ROLE) {
        vaults[propertyId].isActive = true;
    }

    /// @notice Allows admin to withdraw stablecoin balance held in the vault
    /// @param to Destination wallet address to receive the stablecoin balance
    function withdrawStablecoin(address to) external onlyRole(ADMIN_ROLE) {
        uint256 balance = stablecoin.balanceOf(address(this));
        require(balance > 0, "No stablecoin to withdraw");

        stablecoin.safeTransfer(to, balance);
        emit StablecoinWithdrawn(to, balance);
    }

    /// @notice Public function for investors to buy property tokens using stablecoins
    /// @dev Enforces KYC, prevents overselling, uses nonReentrant
    /// @param propertyId ID of the property being invested in
    /// @param stablecoinAmount Amount of stablecoin investor wants to spend (6 decimals)
    function invest(uint256 propertyId, uint256 stablecoinAmount) external onlyKYCInvestor nonReentrant {
        PropertyVault storage vault = vaults[propertyId];

        require(vault.isActive, "Vault inactive");
        require(stablecoinAmount > 0, "No stablecoin sent");
        require(vault.unsoldTokens > 0, "Sold out");

        // Calculate equivalent token amount for stablecoin input
        uint256 tokenAmount = (stablecoinAmount * 1e18) / vault.tokenPriceUSD;
        require(tokenAmount > 0, "Not enough stablecoin for 1 token");
        require(tokenAmount <= vault.unsoldTokens, "Exceeds supply");

        vault.unsoldTokens -= tokenAmount;

        stablecoin.safeTransferFrom(msg.sender, address(this), stablecoinAmount);
        IERC20(vault.token).safeTransfer(msg.sender, tokenAmount);

        emit TokensPurchased(propertyId, msg.sender, tokenAmount, stablecoinAmount);
    }

    /// @notice Returns full metadata of a vault for a given property
    /// @param propertyId ID of the property vault to inspect
    function getVault(uint256 propertyId) external view returns (PropertyVault memory) {
        return vaults[propertyId];
    }
}
