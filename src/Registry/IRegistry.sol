// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./RegistryStorage.sol";

interface IRegistry {
    // Events
    // Events
    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed realtor,
        string name,
        string description,
        uint256 listedFee,
        string metadataURI,
        uint256 timestamp
    );
    event TokenLinked(uint256 indexed propertyId, address tokenAddress);
    event PropertyStatusUpdated(uint256 indexed propertyId, bool isActive);
    event PropertyDeactivated(uint256 indexed propertyId);
    event TokenFactoryUpdated(address newFactory);
    event FeeTransferred(address indexed recipient, uint256 amount);
    event FeeRecipientUpdated(address newRecipient);
    event RealtorPropertyUpdated(address indexed realtor, uint256 newPropertyId, uint256[] propertyIds);
    event RealtorPropertyCount(address indexed realtor, uint256 totalProperties);

    // Struct (must match RegistryStorage)
    // struct Property {
    //     uint256 id;
    //     string name;
    //     string location;
    //     uint256 totalValue;
    //     address tokenAddress;
    //     address realtor;
    //     string description;
    //     bool isActive;
    //     string metadataURI;
    //     uint256 listedFee;
    //     uint256 pricePerToken;
    //     uint256 timestamp;
    // }

    // Functions
    function registerProperty(
        string calldata _name,
        string calldata _location,
        uint256 _totalValueUSD,
        string calldata _description,
        uint256 _pricePerTokenUSD,
        string calldata _metadataURI
    ) external payable;

    function getProperty(uint256 propertyId) external view returns (RegistryStorage.Property memory);

    function getAllProperties() external view returns (RegistryStorage.Property[] memory);

    function updatePropertyStatus(uint256 propertyId, bool _isActive) external;

    function grantRealtorRole(address realtor) external;

    function revokeRealtorRole(address realtor) external;

    function getPropertiesByRealtor(address _realtor) external view returns (uint256[] memory);

    function updateFeeRecipient(address newRecipient) external;

    function withdraw() external;

    function updateTokenFactory(address newFactory) external;
}
