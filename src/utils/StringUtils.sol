// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title StringUtils
/// @notice Utility library for converting uint256 to string (used for dynamic token symbols)
library StringUtils {
    /// @notice Converts a uint256 to its decimal string representation
    /// @param value The uint256 number to convert
    /// @return The number represented as a string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";

        uint256 temp = value;
        uint256 digits;

        // Count the number of digits in `value`
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        // Convert each digit to a character from right to left
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); // ASCII conversion
            value /= 10;
        }

        return string(buffer);
    }
}
