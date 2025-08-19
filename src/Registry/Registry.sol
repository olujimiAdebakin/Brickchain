// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; // Chainlink price feed
import {RegistryStorage} from "./RegistryStorage.sol"; // Property storage struct
import {IRegistry} from "./IRegistry.sol"; // Registry interface
import {ITokenFactory} from "../interfaces/ITokenFactory.sol"; // Token factory interface
import {PriceConverter} from "../utils/PriceConverter.sol"; // USD/ETH conversion utils
import {SymbolUtils} from "../utils/SymbolUtils.sol"; // Symbol/name generation
import {StringUtils} from "../utils/StringUtils.sol"; // String helpers
import {IKYCManager} from "../interfaces/IKYCManager.sol"; // KYC manager interface
import {AccessManager} from "../access/AccessManager.sol"; // Centralized access/pausable

/// @title Registry
/// @notice Main contract for property registration and tokenization in Brickchain
contract Registry is AccessManager, RegistryStorage, IRegistry {
    using StringUtils for uint256;
    using StringUtils for string;
    using SymbolUtils for string;
    using PriceConverter for uint256;

    IKYCManager public kycManager; // KYC manager contract
    address public vault; // Vault contract address for holding property tokens

    /// @notice Deploys Registry and sets up dependencies
    constructor(
        address admin,
        address _tokenFactory,
        uint256 _listingFee,
        address _feeRecipient,
        address _priceFeed,
        address _kycManager,
        address _vault
    ) AccessManager(admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin); // Grant admin role
        _setTokenFactory(_tokenFactory); // Set token factory
        listingFee = _listingFee; // Set listing fee
        _setFeeRecipient(_feeRecipient); // Set fee recipient
        priceFeed = AggregatorV3Interface(_priceFeed); // Set Chainlink price feed
        kycManager = IKYCManager(_kycManager); // Set KYC manager
        vault = _vault; // Set vault address
    }

    // ========== MODIFIERS ==========

    /// @notice Restricts to realtors only
    modifier onlyRealtor() {
        require(hasRole(REALTOR_ROLE, msg.sender), "Not authorized: Realtor only");
        _;
    }

    /// @notice Checks if propertyId is valid
    modifier validProperty(uint256 propertyId) {
        require(propertyId > 0 && propertyId <= propertyCounter, "Invalid property ID");
        _;
    }

    // ========== MAIN FUNCTIONS ==========

    /// @notice Register a new property and mint tokens to the vault
    function registerProperty(
        string calldata _name,
        string calldata _location,
        uint256 _totalValueUSD,
        string calldata _description,
        uint256 _pricePerTokenUSD,
        string calldata _metadataURI
    ) external payable onlyRealtor {
        // Input validation
        require(kycManager.isKYCApproved(msg.sender), "KYC not approved");
        require(_totalValueUSD > 0, "Total property value must be > 0");
        require(bytes(_name).length > 0, "Property name is required");
        require(_isValidURI(_metadataURI), "Invalid metadata URI");

        // Tier-based pricing validation
        if (_totalValueUSD < 50_000) {
            require(_pricePerTokenUSD == 5, "Token price must be $5 for properties < $50k");
        } else if (_totalValueUSD <= 150_000) {
            require(_pricePerTokenUSD == 10, "Token price must be $10 for $50k-$150k");
        } else {
            require(_pricePerTokenUSD == 20, "Token price must be $20 for properties > $150k");
        }

        // Listing fee calculation and transfer
        uint256 listingFeeUSD = (_totalValueUSD * 15) / 100; // 15% listing fee
        uint256 listingFeeETH = listingFeeUSD.getETHAmountFromUSD(priceFeed); // Convert USD to ETH
        require(msg.value >= listingFeeETH, "Insufficient listing fee");

        (bool sent,) = feeRecipient.call{value: msg.value}(""); // Transfer ETH to fee recipient
        require(sent, "Fee transfer failed");
        emit FeeTransferred(feeRecipient, msg.value);

        // Property registration and token minting
        propertyCounter++; // Increment property counter
        uint256 newPropertyId = propertyCounter;

        string memory tokenSymbol = SymbolUtils.generateSymbol(_name, newPropertyId); // Generate symbol
        string memory tokenName = SymbolUtils.generateName(_name, newPropertyId); // Generate name
        uint256 tokenSupply = _calculateTokenSupply(_totalValueUSD, _pricePerTokenUSD); // Calculate supply

        // Mint tokens to the vault
        address token = tokenFactory.createToken(
            _name, // string name (for UI)
            string(abi.encodePacked("BRICK", newPropertyId.toString())), // string symbol
            tokenSupply, // uint256 totalSupply
            tokenName, // string tokenName (ERC20)
            tokenSymbol, // string tokenSymbol (ERC20)
            _metadataURI, // string propertyURI
            address(kycManager), // address kycManager
            address(this), // address owner (Registry)
            vault // address vault
        );
        require(token != address(0), "Token creation failed");

        // Store property data
        properties[newPropertyId] = RegistryStorage.Property({
            id: newPropertyId,
            name: _name,
            location: _location,
            totalValue: _totalValueUSD,
            tokenAddress: token,
            realtor: msg.sender,
            description: _description,
            isActive: true,
            vault: vault, // Vault address
            metadataURI: _metadataURI,
            listedFee: listingFeeUSD,
            pricePerToken: _pricePerTokenUSD,
            timestamp: block.timestamp,
            tokenSupply: tokenSupply,
            realtorPropertyCount: realtorToProperties[msg.sender].length + 1
        });

        realtorToProperties[msg.sender].push(newPropertyId); // Track realtor's properties

        // Emit events for registration and token linkage
        emit PropertyRegistered(
            newPropertyId, msg.sender, _name, _description, listingFeeUSD, _metadataURI, block.timestamp
        );
        emit RealtorPropertyCount(msg.sender, realtorToProperties[msg.sender].length);
        emit TokenLinked(newPropertyId, token);
    }

    // ========== INTERNAL FUNCTIONS ==========

    /// @notice Calculate token supply based on property value and price per token
    function _calculateTokenSupply(uint256 totalValueUSD, uint256 pricePerTokenUSD) internal pure returns (uint256) {
        require(pricePerTokenUSD > 0, "Token price must be greater than zero");
        return (totalValueUSD * 1e18) / pricePerTokenUSD;
    }

    /// @notice Validate metadata URI (must start with ipfs:// or https://)
    function _isValidURI(string calldata uri) internal pure returns (bool) {
        bytes memory uriBytes = bytes(uri);
        if (uriBytes.length < 9) return false;

        bytes memory ipfsPrefix = bytes("ipfs://");
        bytes memory httpsPrefix = bytes("https://");

        return _startsWith(uriBytes, ipfsPrefix) || _startsWith(uriBytes, httpsPrefix);
    }

    /// @notice Helper to check if data starts with prefix
    function _startsWith(bytes memory data, bytes memory prefix) internal pure returns (bool) {
        if (data.length < prefix.length) return false;
        for (uint256 i = 0; i < prefix.length; i++) {
            if (data[i] != prefix[i]) return false;
        }
        return true;
    }

    // ========== VIEW FUNCTIONS ==========

    /// @notice Public view for token supply calculation
    function calculateTokenSupply(uint256 totalValueUSD, uint256 pricePerTokenUSD) public pure returns (uint256) {
        return _calculateTokenSupply(totalValueUSD, pricePerTokenUSD);
    }

    /// @notice Update property status (active/inactive)
    function updatePropertyStatus(uint256 propertyId, bool _isActive) external validProperty(propertyId) {
        Property storage prop = properties[propertyId];
        require(msg.sender == prop.realtor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        prop.isActive = _isActive;
        emit PropertyStatusUpdated(propertyId, _isActive);
    }

    /// @notice Deactivate property (admin only)
    function deactivateProperty(uint256 propertyId) external onlyRole(DEFAULT_ADMIN_ROLE) validProperty(propertyId) {
        properties[propertyId].isActive = false;
        emit PropertyDeactivated(propertyId);
    }

    /// @notice Grant realtor role to an address (admin only)
    function grantRealtorRole(address realtor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(REALTOR_ROLE, realtor);
    }

    /// @notice Revoke realtor role from an address (admin only)
    function revokeRealtorRole(address realtor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(REALTOR_ROLE, realtor);
    }

    /// @notice Get all property IDs for a realtor
    function getPropertiesByRealtor(address _realtor) external view returns (uint256[] memory) {
        return realtorToProperties[_realtor];
    }

    /// @notice Get property details by propertyId
    function getProperty(uint256 propertyId)
        external
        view
        validProperty(propertyId)
        returns (RegistryStorage.Property memory)
    {
        return properties[propertyId];
    }

    /// @notice Update fee recipient address (admin only)
    function updateFeeRecipient(address newRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /// @notice Withdraw ETH from contract (admin only)
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(feeRecipient).transfer(balance);
    }

    /// @notice Update token factory address (admin only)
    function updateTokenFactory(address newFactory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFactory != address(0), "Invalid address");
        tokenFactory = ITokenFactory(newFactory);
        emit TokenFactoryUpdated(newFactory);
    }

    /// @notice Get all registered properties
    function getAllProperties() external view returns (RegistryStorage.Property[] memory) {
        RegistryStorage.Property[] memory props = new RegistryStorage.Property[](propertyCounter);
        for (uint256 i = 1; i <= propertyCounter; i++) {
            props[i - 1] = properties[i];
        }
        return props;
    }

    // ========== PRIVATE HELPERS ==========

    /// @notice Set token factory address (internal)
    function _setTokenFactory(address _tokenFactory) private {
        require(_tokenFactory != address(0), "Invalid token factory");
        tokenFactory = ITokenFactory(_tokenFactory);
    }

    /// @notice Set fee recipient address (internal)
    function _setFeeRecipient(address _feeRecipient) private {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }
}
