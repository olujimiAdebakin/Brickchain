// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title PriceConverter
/// @notice Library to fetch and convert ETH/USD price using Chainlink
library PriceConverter {
    /// @notice Gets the latest ETH/USD price
    /// @param priceFeed The Chainlink Aggregator interface
    /// @return ETH price in 8 decimals (e.g., 3000.00 = 300000000)
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price); // 8 decimals
    }

    /// @notice Converts USD value to equivalent ETH in wei
    /// @param usdAmount USD amount (no decimals)
    /// @param priceFeed Chainlink ETH/USD price feed
    /// @return Equivalent ETH amount in wei
    function getETHAmountFromUSD(uint256 usdAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getLatestPrice(priceFeed); // in 8 decimals
        return (usdAmount * 1e18 * 1e8) / ethPrice; // convert USD to ETH
    }
}
