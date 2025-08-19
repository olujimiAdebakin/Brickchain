// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library SymbolUtils {
    using Strings for uint256;

    function sanitizeName(string memory name) internal pure returns (string memory) {
        bytes memory nameBytes = bytes(name);
        bytes memory cleaned = new bytes(nameBytes.length);
        uint256 j = 0;
        for (uint256 i = 0; i < nameBytes.length && j < 8; i++) {
            bytes1 char = nameBytes[i];
            if ((char >= 0x30 && char <= 0x39) || (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A)) {
                // Convert lowercase to uppercase
                if (char >= 0x61 && char <= 0x7A) {
                    char = bytes1(uint8(char) - 32);
                }
                cleaned[j++] = char;
            }
        }
        bytes memory result = new bytes(j);
        for (uint256 k = 0; k < j; k++) {
            result[k] = cleaned[k];
        }
        return string(result);
    }

    function formatId(uint256 id) internal pure returns (string memory) {
        if (id < 10) return string(abi.encodePacked("00", id.toString()));
        if (id < 100) return string(abi.encodePacked("0", id.toString()));
        return id.toString();
    }

    function generateSymbol(string memory name, uint256 id) internal pure returns (string memory) {
        return string(abi.encodePacked("BRICK", sanitizeName(name), formatId(id)));
    }

    function generateName(string memory name, uint256 id) internal pure returns (string memory) {
        return string(abi.encodePacked("Brick ", name, " #", id.toString()));
    }
}
