// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// // import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "../src/access/AccessManager.sol";
// import "../src/interfaces/IKYCManager.sol";

// /// @title Escrow
// /// @notice Manages secure token and stablecoin transfers for Marketplace trades
// contract MarketPlaceEscrow is AccessManager {
//     IKYCManager public kycManager;
//     IERC20 public stablecoin;
//     address public marketplace;

//     struct EscrowTrade {
//         uint256 escrowId;
//         address seller;
//         address buyer;
//         address token;
//         uint256 tokenAmount;
//         uint256 stablecoinAmount;
//         bool sellerConfirmed;
//         bool buyerConfirmed;
//         bool isActive;
//     }

//     uint256 public escrowCounter;
//     mapping(uint256 => EscrowTrade) public escrows;

//     event EscrowCreated(
//         uint256 indexed escrowId,
//         address indexed seller,
//         address indexed buyer,
//         address token,
//         uint256 tokenAmount,
//         uint256 stablecoinAmount
//     );
//     event EscrowConfirmed(uint256 indexed escrowId, address indexed confirmer);
//     event EscrowReleased(uint256 indexed escrowId);
//     event EscrowCancelled(uint256 indexed escrowId);

//     /// @notice Deploys Escrow with dependencies
//     constructor(
//         address admin,
//         address _kycManager,
//         address _stablecoin,
//         address _marketplace
//     ) AccessManager(admin) {
//         require(_kycManager != address(0), "Invalid KYCManager address");
//         require(_stablecoin != address(0), "Invalid Stablecoin address");
//         require(_marketplace != address(0), "Invalid Marketplace address");
//         kycManager = IKYCManager(_kycManager);
//         stablecoin = IERC20(_stablecoin);
//         marketplace = _marketplace;
//         _grantRole(DEFAULT_ADMIN_ROLE, admin);
//     }

//     /// @notice Restricts to KYC-approved investors or marketplace
//     modifier onlyAuthorized(address user) {
//         require(
//             (hasRole(INVESTOR_ROLE, user) && kycManager.isKYCApproved(user)) ||
//             user == marketplace,
//             "Not authorized"
//         );
//         _;
//     }

//     /// @notice Creates an escrow for a trade
//     function createEscrow(
//         address seller,
//         address buyer,
//         address token,
//         uint256 tokenAmount,
//         uint256 stablecoinAmount
//     ) external onlyRole(MARKETPLACE_ROLE) returns (uint256) {
//         require(seller != address(0) && buyer != address(0), "Invalid addresses");
//         require(token != address(0), "Invalid token address");
//         require(tokenAmount > 0 && stablecoinAmount > 0, "Invalid amounts");

//         escrowCounter++;
//         uint256 escrowId = escrowCounter;
//         escrows[escrowId] = EscrowTrade({
//             escrowId: escrowId,
//             seller: seller,
//             buyer: buyer,
//             token: token,
//             tokenAmount: tokenAmount,
//             stablecoinAmount: stablecoinAmount,
//             sellerConfirmed: false,
//             buyerConfirmed: false,
//             isActive: true
//         });

//         // Transfer tokens and stablecoins to escrow
//         require(IERC20(token).transferFrom(seller, address(this), tokenAmount), "Token transfer failed");
//         require(stablecoin.transferFrom(buyer, address(this), stablecoinAmount), "Stablecoin transfer failed");

//         emit EscrowCreated(escrowId, seller, buyer, token, tokenAmount, stablecoinAmount);
//         return escrowId;
//     }

//     /// @notice Confirms an escrow trade
//     function confirmEscrow(uint256 escrowId) external onlyAuthorized(msg.sender) nonReentrant {
//         EscrowTrade storage trade = escrows[escrowId];
//         require(trade.isActive, "Escrow inactive or invalid");
//         require(msg.sender == trade.seller || msg.sender == trade.buyer, "Not escrow participant");

//         if (msg.sender == trade.seller) {
//             trade.sellerConfirmed = true;
//         } else {
//             trade.buyerConfirmed = true;
//         }

//         emit EscrowConfirmed(escrowId, msg.sender);

//         if (trade.sellerConfirmed && trade.buyerConfirmed) {
//             releaseEscrow(escrowId);
//         }
//     }

//     /// @notice Releases escrow funds and tokens
//     function releaseEscrow(uint256 escrowId) internal {
//         EscrowTrade storage trade = escrows[escrowId];
//         require(trade.isActive, "Escrow inactive");
//         require(trade.sellerConfirmed && trade.buyerConfirmed, "Not fully confirmed");

//         trade.isActive = false;
//         require(IERC20(trade.token).transfer(trade.buyer, trade.tokenAmount), "Token transfer failed");
//         require(stablecoin.transfer(trade.seller, trade.stablecoinAmount), "Stablecoin transfer failed");

//         emit EscrowReleased(escrowId);
//     }

//     /// @notice Cancels an escrow trade (admin only)
//     function cancelEscrow(uint256 escrowId) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
//         EscrowTrade storage trade = escrows[escrowId];
//         require(trade.isActive, "Escrow inactive");

//         trade.isActive = false;
//         require(IERC20(trade.token).transfer(trade.seller, trade.tokenAmount), "Token refund failed");
//         require(stablecoin.transfer(trade.buyer, trade.stablecoinAmount), "Stablecoin refund failed");

//         emit EscrowCancelled(escrowId);
//     }

//     /// @notice Gets escrow details
//     function getEscrow(uint256 escrowId) external view returns (EscrowTrade memory) {
//         return escrows[escrowId];
//     }
// }