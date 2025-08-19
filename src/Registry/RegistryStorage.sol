// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/ITokenFactory.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

abstract contract RegistryStorage {
    // Roles
    // bytes32 public constant REALTOR_ROLE = keccak256("REALTOR_ROLE");

    // Configuration
    address public feeRecipient;
    uint256 public listingFee;
    ITokenFactory public tokenFactory;
    AggregatorV3Interface public priceFeed;

    // Counters
    uint256 public propertyCounter;

    // Property Data Structure
    struct Property {
        uint256 id;
        string name;
        string location;
        uint256 totalValue;
        address tokenAddress;
        address realtor;
        string description;
        bool isActive;
        string metadataURI;
        uint256 listedFee;
        uint256 pricePerToken;
        uint256 timestamp;
        uint256 realtorPropertyCount;
        uint256 tokenSupply;
        address vault;
    }

    // Mappings
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public realtorToProperties;
}
