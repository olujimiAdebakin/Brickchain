
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Registry/Registry.sol";

contract RegisterProperty is Script {
    /// @notice Registers a property on the Registry contract
    /// @dev Run with realtor's private key, requires REALTOR_ROLE and KYC approval
    function run() external {
        bytes32 realtorPrivateKey = vm.envBytes32("REALTOR_PRIVATE_KEY");
        address realtor = vm.envAddress("REALTOR_ADDRESS");
        console.log("Realtor address:", realtor);

        address registry = vm.envAddress("REGISTRY_ADDRESS");
        address priceFeed = vm.envAddress("PRICE_FEED_ADDRESS");
        console.log("Registry address:", registry);
        console.log("Price feed address:", priceFeed);

        require(registry != address(0), "Invalid Registry address");
        require(priceFeed != address(0), "Invalid Price Feed address");

        // Property details
        string memory name = "Obed Apartment";
        string memory location = "123 Enugu St, Enugu";
        uint256 totalValueUSD = 100_000; // $100k
        string memory description = "Modern 3-bedroom apartment";
        uint256 pricePerTokenUSD = 10; // $10 per token (for $50k-$150k tier)
        string memory metadataURI = "ipfs://QmExampleHash";

        // Calculate listing fee in ETH (15% of totalValueUSD)
        uint256 listingFeeUSD = (totalValueUSD * 15) / 100; // $15,000
        uint256 listingFeeETH = listingFeeUSD.getETHAmountFromUSD(AggregatorV3Interface(priceFeed));
        console.log("Listing fee (ETH):", listingFeeETH);

        vm.startBroadcast(uint256(realtorPrivateKey));
        Registry reg = Registry(registry);
        reg.registerProperty{value: listingFeeETH}(
            name,
            location,
            totalValueUSD,
            description,
            pricePerTokenUSD,
            metadataURI
        );
        console.log("Property registered by:", realtor);
        vm.stopBroadcast();
    }
}