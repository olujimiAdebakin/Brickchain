// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// // OpenZeppelin library for role-based access control
// import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// // String conversion helper for uint256 -> string (used in symbol naming)
// import {StringUtils} from "./utils/StringUtils.sol";

// // Import the AggregatorV3Interface contract from Chainlink
// import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// // Import price-converter library
// import {PriceConverter} from "./utils/PriceConverter.sol";

// import {SymbolUtils} from "./utils/SymbolUtils.sol";

// // Interface to the TokenFactory responsible for creating property tokens
// interface ITokenFactory {
//     function createToken(
//         string calldata name,
//         string calldata symbol,
//         uint256 totalSupply,
//         address owner
//     ) external returns (address);
// }

// contract Registry is AccessControl {
//     using StringUtils for uint256;
//     using PriceConverter for uint256;
//     using StringUtils for string;
//     using SymbolUtils for string;

//     // Role constant for Realtors
//     bytes32 public constant REALTOR_ROLE = keccak256("REALTOR_ROLE");

//     // Counter to track number of registered properties
//     uint256 public propertyCounter;

//     // TokenFactory contract to mint new tokens
//     ITokenFactory public tokenFactory;

//     // Fixed listing fee in USD (percentage of property value)
//     uint256 public listingFee; // Not used after dynamic fee is introduced

//     // Address to receive listing fees
//     address public feeRecipient;

//     // Chainlink Price Feed for ETH/USD
//     AggregatorV3Interface internal priceFeed;

//     // Symbol Utils to sanitize the token symbol
//     using SymbolUtils for string;

//     // Property structure
//     struct Property {
//         uint256 id;
//         string name;
//         string location;
//         uint256 totalValue;      // Property value in USD
//         address tokenAddress;    // ERC20 token address tied to this property
//         address realtor;         // Realtor who registered the property
//         string description;      // Property description
//         bool isActive;           // Active status (soft delete)
//         string metadataURI;      // Metadata image or JSON
//         uint256 listedFee;       // Listing fee charged (in USD)
//         uint256 pricePerToken;   // Price per token
//         uint256 timestamp;       // Timestamp of last update
//     }

//     // Mappings
//     // property recordss
//     mapping(uint256 => Property) public properties;
//     mapping(address => uint256[]) public realtorToProperties;

//     // Events
//     event PropertyRegistered(
//         uint256 indexed propertyId,
//         address indexed realtor,
//         string name,
//         string description,
//         uint256 listedFee,
//         string metadataURI,
//         uint256 timestamp
//     );
//     event TokenLinked(uint256 indexed propertyId, address tokenAddress);
//     event PropertyStatusUpdated(uint256 indexed propertyId, bool isActive);
//     event PropertyDeactivated(uint256 indexed propertyId);
//     event TokenFactoryUpdated(address newFactory);
//     event FeeTransferred(address indexed recipient, uint256 amount);
//     event FeeRecipientUpdated(address newRecipient);

//     /// @notice Constructor to initialize the contract
//     /// @param admin Address with admin privileges
//     /// @param _tokenFactory TokenFactory address
//     /// @param _listingFee Static listing fee (not used anymore)
//     /// @param _feeRecipient Address to collect listing fees
//     /// @param _priceFeed Address of the Chainlink price feed contract
//     constructor(
//         address admin,
//         address _tokenFactory,
//         uint256 _listingFee,
//         address _feeRecipient,
//         address _priceFeed
//     ) {
//         _grantRole(DEFAULT_ADMIN_ROLE, admin);
//         tokenFactory = ITokenFactory(_tokenFactory);
//         listingFee = _listingFee;
//         feeRecipient = _feeRecipient;
//         priceFeed = AggregatorV3Interface(_priceFeed); // for example ETH or USD
//     }

//     // Restrict function to only Realtors
//     modifier onlyRealtor() {
//         require(hasRole(REALTOR_ROLE, msg.sender), "Not authorized: Realtor only");
//         _;
//     }

//     /// @notice Register a new property and mint a token
//     // Register a property and create associated token
//     /// @notice Registers a new property and creates a token representing its value.
//     /// @dev Enforces tiered token pricing and calculates listing fees in ETH.
//     /// @param _name Name of the property.
//     /// @param _location Physical or virtual address of the property.
//     /// @param _totalValueUSD Total property value in USD.
//     /// @param _description Description of the property.
//     /// @param _pricePerTokenUSD Price per token in USD set by the realtor, within a valid range based on tiers.
//     /// @param _metadataURI Metadata URI (e.g. image or JSON).
//     function registerProperty(
//         string memory _name,
//         string memory _location,
//         uint256 _totalValueUSD,
//         string memory _description,
//         uint256 _pricePerTokenUSD,
//         string memory _metadataURI
//     ) external payable onlyRealtor {
//         // Defensive check
//         require(_totalValueUSD > 0, "Total property value must be > 0");
//         require(bytes(_name).length > 0, "Property name is required");
//         require(
//             bytes(_metadataURI).length > 8 &&
//             (bytes(_metadataURI).startsWith("ipfs://") || bytes(_metadataURI).startsWith("https://")),
//             "Invalid metadata URI"
//         );

//         // --- Enforcing tiered based pricing rules i am tired ooo obed---
//         if (_totalValueUSD < 50000) {
//             require(_pricePerTokenUSD == 5, "Token price must be exactly $5 for properties under $50k");
//         } else if (_totalValueUSD >= 50000 && _totalValueUSD <= 150000) {
//             require(
//                 _pricePerTokenUSD == 10,
//                 "Token price must be exactly and $1o for properties between $50k and $150k"
//             );
//         } else {
//             require(
//                 _pricePerTokenUSD == 20,
//                 "Token price must be exactly $20 for properties over $150k"
//             );
//         }

//         // --- CALCULATE 15% LISTING FEE IN USD ---
//         uint256 listingFeeUSD = (_totalValueUSD * 15) / 100;

//         // --- CONVERT USD FEE TO ETH ---
//         uint256 listingFeeETH = listingFeeUSD.getETHAmountFromUSD(priceFeed);

//         // --- VALIDATE PAYMENT ---
//         require(msg.value >= listingFeeETH, "Insufficient listing fee");

//         // --- FORWARD THE FEE ---
//         (bool sent, ) = feeRecipient.call{value: msg.value}("");
//         require(sent, "Fee transfer failed");

//         emit FeeTransferred(feeRecipient, msg.value);

//         // uint256 pricePerToken = 5; // $5 per token
//         // uint8 tokenDecimals = 18;
//         // uint256 scaledTotalValue = _totalValueUSD * (10 ** tokenDecimals);
//         // uint256 tokenSupply = scaledTotalValue / pricePerToken;

//         uint256 tokenSupply = calculateTokenSupply(_totalValueUSD, pricePerToken);

//         // --- CONTINUE PROPERTY REGISTRATION ---

//         // Increment property counter for unique ID and symbol
//         propertyCounter++;

//         // Generate dynamic token name and symbol based on property name and counter
//         string memory tokenSymbol = SymbolUtils.generateSymbol(_name, propertyCounter);
//         string memory tokenName = SymbolUtils.generateName(_name, propertyCounter);

//         // --- CREATE PROPERTY TOKEN ---
//         address token = tokenFactory.createToken(
//             _name,
//             string(abi.encodePacked("BRICK", propertyCounter.toString())),
//             tokenSupply,
//             tokenName,
//             tokenSymbol,
//             msg.sender
//         );

//         // --- STORE PROPERTY ---
//         properties[propertyCounter] = Property({
//             id: propertyCounter,
//             name: _name,
//             location: _location,
//             totalValue: _totalValueUSD,
//             tokenAddress: token,
//             realtor: msg.sender,
//             description: _description,
//             isActive: true,
//             metadataURI: _metadataURI,
//             listedFee: listingFeeUSD,
//             pricePerToken: _pricePerTokenUSD,
//             timestamp: block.timestamp
//         });

//         realtorToProperties[msg.sender].push(propertyCounter);

//         emit PropertyRegistered(propertyCounter, msg.sender, _name, _description, listingFeeUSD, _metadataURI, block.timestamp);
//         emit TokenLinked(propertyCounter, token);
//     }

//     /// @notice Helper to calculate token supply based on USD value and token price
//     /// @param totalValueUSD The total property value in USD
//     /// @param pricePerTokenUSD The price of one token in USD
//     /// @return tokenSupply Total supply of tokens to mint (in 18 decimals)
//     function calculateTokenSupply(uint256 totalValueUSD, uint256 pricePerTokenUSD) public pure returns (uint256) {
//         require(pricePerTokenUSD > 0, "Token price must be greater than zero");

//         uint8 tokenDecimals = 18;
//         uint256 scaledTotalValue = totalValueUSD * (10 ** tokenDecimals);
//         uint256 tokenSupply = scaledTotalValue / (pricePerTokenUSD * 1e18 / 1e18);
//         return tokenSupply;
//     }

//     /// @notice Update the status of a property (Active/Inactive)
//     function updatePropertyStatus(uint256 propertyId, bool _isActive) external {
//         Property storage prop = properties[propertyId];
//         require(msg.sender == prop.realtor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
//         prop.isActive = _isActive;
//         emit PropertyStatusUpdated(propertyId, _isActive);
//     }

//     /// @notice Soft delete a property by Admin
//     function deactivateProperty(uint256 propertyId) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         Property storage prop = properties[propertyId];
//         prop.isActive = false;
//         emit PropertyDeactivated(propertyId);
//     }

//     /// @notice Grant Realtor role to an address
//     function grantRealtorRole(address realtor) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         grantRole(REALTOR_ROLE, realtor);
//     }

//     function revokeRealtorRole(address realtor) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         revokeRole(REALTOR_ROLE, realtor);
//     }

//     /// @notice Get all properties owned by a Realtor
//     // View all property IDs created by a Realtor
//     function getPropertiesByRealtor(address _realtor) external view returns (uint256[] memory) {
//         return realtorToProperties[_realtor];
//     }

//     /// @notice Fetch property details by ID
//     function getProperty(uint256 propertyId) external view returns (Property memory) {
//         return properties[propertyId];
//     }

//     function updateFeeRecipient(address newRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         require(newRecipient != address(0), "Invalid address");
//         feeRecipient = newRecipient;
//         emit FeeRecipientUpdated(newRecipient);
//     }

//     /// @notice Checks that the contract has a non-zero balance.
//     // Transfers all ETH to feeRecipient.
//     // Can only be called by an address with DEFAULT_ADMIN_ROLE.
//     // Prevents ETH from being permanently locked inside.
//     // Supports good contract hygiene and better treasury control.
//     function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
//         uint256 balance = address(this).balance;
//         require(balance > 0, "No ETH to withdraw");
//         payable(feeRecipient).transfer(balance);
//     }

//     /// @notice Update TokenFactory address (Admin only)
//     function updateTokenFactory(address newFactory) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         require(newFactory != address(0), "Invalid address");
//         tokenFactory = ITokenFactory(newFactory);
//         emit TokenFactoryUpdated(newFactory);
//     }

//     /// @notice Frontend use
//     function getAllProperties() external view returns (Property[] memory) {
//         Property[] memory props = new Property[](propertyCounter);
//         for (uint256 i = 1; i <= propertyCounter; i++) {
//             props[i - 1] = properties[i];
//         }
//         return props;
//     }
// }
