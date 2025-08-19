// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITokenFactory} from "../../src/interfaces/ITokenFactory.sol";

contract MockTokenFactory is ITokenFactory {
    address public lastCreatedToken;

    function createToken(
        string memory, // _displayName
        string memory, // _displaySymbol
        uint256, // _supply
        string memory, // _name
        string memory, // _symbol
        string memory, // _propertyURI
        address, // _kycManager
        address, // _owner
        address // _vault
    ) external override returns (address) {
        lastCreatedToken = address(0x1234); // Mock token address
        return lastCreatedToken;
    }
}
