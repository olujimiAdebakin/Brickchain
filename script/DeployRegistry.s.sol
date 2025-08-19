// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Registry/Registry.sol";

contract DeployRegistry is Script {
    /// @notice Deploys the Registry contract for Brickchain
    /// @dev Loads constructor arguments from environment variables and deploys Registry
    function run() external {
        // @dev Load private key and derive deployer address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        // @dev Load constructor arguments from environment variables
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address tokenFactory = vm.envAddress("TOKEN_FACTORY_ADDRESS");
        uint256 listingFee = vm.envUint("LISTING_FEE");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT_ADDRESS");
        address priceFeed = vm.envAddress("PRICE_FEED_ADDRESS");
        address kycManager = vm.envAddress("KYC_MANAGER_ADDRESS");
        address vault = vm.envAddress("VAULT_ADDRESS");

        // @notice Log constructor arguments for debugging
        console.log("Admin address:", admin);
        console.log("Token Factory address:", tokenFactory);
        console.log("Listing Fee:", listingFee);
        console.log("Fee Recipient address:", feeRecipient);
        console.log("Price Feed address:", priceFeed);
        console.log("KYC Manager address:", kycManager);
        console.log("Vault address:", vault);

        // @notice Validate constructor arguments
        // @dev Ensure non-zero addresses and valid listing fee
        require(admin != address(0), "Invalid admin address");
        require(tokenFactory != address(0), "Invalid token factory address");
        require(feeRecipient != address(0), "Invalid fee recipient address");
        require(priceFeed != address(0), "Invalid price feed address");
        require(kycManager != address(0), "Invalid KYC manager address");
        require(vault != address(0), "Invalid vault address");
        require(listingFee > 0, "Listing fee must be greater than 0");
        console.log("Constructor arguments validated successfully");

        // @notice Start broadcasting transactions
        // @dev Use deployer’s private key for signing
        vm.startBroadcast(deployerPrivateKey);

        // @notice Deploy Registry contract
        // @dev Pass all required constructor arguments
        Registry registry = new Registry(
            admin,
            tokenFactory,
            listingFee,
            feeRecipient,
            priceFeed,
            kycManager,
            vault
        );
        console.log("Registry deployed to:", address(registry));

        // @dev Stop broadcasting transactions
        vm.stopBroadcast();

        // @notice Log deployment completion
        // @dev Confirm deployment success
        console.log("Registry deployment completed by:", deployer);
    }
}