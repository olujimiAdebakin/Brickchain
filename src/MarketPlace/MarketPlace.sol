
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// // import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "../src/access/AccessManager.sol";
// import "../src/interfaces/IKYCManager.sol";
// import "../src/escrow/Escrow.sol";

// /// @title Marketplace
// /// @notice Manages buying and selling of property tokens with stablecoin payments
// contract Marketplace is AccessManager{
//     IKYCManager public kycManager;
//     Escrow public escrow;
//     IERC20 public stablecoin;

//     struct Listing {
//         uint256 listingId;
//         address seller;
//         address token;
//         uint256 amount;
//         uint256 pricePerTokenUSD; // Price in USDC (6 decimals)
//         bool isActive;
//     }

//     uint256 public listingCounter;
//     mapping(uint256 => Listing) public listings;
//     mapping(address => uint256[]) public sellerListings;

//     event ListingCreated(
//         uint256 indexed listingId,
//         address indexed seller,
//         address token,
//         uint256 amount,
//         uint256 pricePerTokenUSD
//     );
//     event ListingCancelled(uint256 indexed listingId);
//     event PurchaseInitiated(
//         uint256 indexed listingId,
//         address indexed buyer,
//         uint256 escrowId
//     );

//     /// @notice Deploys Marketplace with dependencies
//     constructor(
//         address admin,
//         address _kycManager,
//         address _escrow,
//         address _stablecoin
//     ) AccessManager(admin) {
//         require(_kycManager != address(0), "Invalid KYCManager address");
//         require(_escrow != address(0), "Invalid Escrow address");
//         require(_stablecoin != address(0), "Invalid Stablecoin address");
//         kycManager = IKYCManager(_kycManager);
//         escrow = Escrow(_escrow);
//         stablecoin = IERC20(_stablecoin);
//         _grantRole(DEFAULT_ADMIN_ROLE, admin);
//     }

//     /// @notice Restricts to KYC-approved investors
//     modifier onlyInvestor() {
//         require(hasRole(INVESTOR_ROLE, msg.sender), "Not authorized: Investor only");
//         require(kycManager.isKYCApproved(msg.sender), "KYC not approved");
//         _;
//     }

//     /// @notice Creates a listing for selling property tokens
//     function createListing(
//         address token,
//         uint256 amount,
//         uint256 pricePerTokenUSD
//     ) external onlyInvestor nonReentrant returns (uint256) {
//         require(token != address(0), "Invalid token address");
//         require(amount > 0, "Amount must be > 0");
//         require(pricePerTokenUSD > 0, "Price must be > 0");
//         require(IERC20(token).balanceOf(msg.sender) >= amount, "Insufficient token balance");
//         require(IERC20(token).allowance(msg.sender, address(escrow)) >= amount, "Approve tokens for Escrow");

//         listingCounter++;
//         uint256 listingId = listingCounter;
//         listings[listingId] = Listing({
//             listingId: listingId,
//             seller: msg.sender,
//             token: token,
//             amount: amount,
//             pricePerTokenUSD: pricePerTokenUSD,
//             isActive: true
//         });
//         sellerListings[msg.sender].push(listingId);

//         emit ListingCreated(listingId, msg.sender, token, amount, pricePerTokenUSD);
//         return listingId;
//     }

//     /// @notice Initiates a purchase by transferring stablecoins to Escrow
//     function buyTokens(uint256 listingId, uint256 amount) external onlyInvestor nonReentrant {
//         Listing storage listing = listings[listingId];
//         require(listing.isActive, "Listing inactive or invalid");
//         require(amount > 0 && amount <= listing.amount, "Invalid amount");
//         require(msg.sender != listing.seller, "Cannot buy own listing");

//         uint256 totalPriceUSD = amount * listing.pricePerTokenUSD;
//         require(stablecoin.balanceOf(msg.sender) >= totalPriceUSD, "Insufficient stablecoin balance");
//         require(stablecoin.allowance(msg.sender, address(escrow)) >= totalPriceUSD, "Approve stablecoins for Escrow");

//         uint256 escrowId = escrow.createEscrow(
//             listing.seller,
//             msg.sender,
//             listing.token,
//             amount,
//             totalPriceUSD
//         );

//         listing.amount -= amount;
//         if (listing.amount == 0) {
//             listing.isActive = false;
//             removeListingFromSeller(listing.seller, listingId);
//         }

//         emit PurchaseInitiated(listingId, msg.sender, escrowId);
//     }

//     /// @notice Cancels a listing
//     function cancelListing(uint256 listingId) external nonReentrant {
//         Listing storage listing = listings[listingId];
//         require(listing.seller == msg.sender, "Not listing owner");
//         require(listing.isActive, "Listing already inactive");

//         listing.isActive = false;
//         removeListingFromSeller(msg.sender, listingId);
//         emit ListingCancelled(listingId);
//     }

//     /// @notice Removes listing from seller's list
//     function removeListingFromSeller(address seller, uint256 listingId) internal {
//         uint256[] storage sellerList = sellerListings[seller];
//         for (uint256 i = 0; i < sellerList.length; i++) {
//             if (sellerList[i] == listingId) {
//                 sellerList[i] = sellerList[sellerList.length - 1];
//                 sellerList.pop();
//                 break;
//             }
//         }
//     }

//     /// @notice Updates Escrow contract address (admin only)
//     function updateEscrow(address newEscrow) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         require(newEscrow != address(0), "Invalid Escrow address");
//         escrow = Escrow(newEscrow);
//     }

//     /// @notice Gets all listings for a seller
//     function getSellerListings(address seller) external view returns (uint256[] memory) {
//         return sellerListings[seller];
//     }

//     /// @notice Gets listing details
//     function getListing(uint256 listingId) external view returns (Listing memory) {
//         return listings[listingId];
//     }
// }