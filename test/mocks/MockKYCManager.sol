// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IKYCManager} from "../../src/interfaces/IKYCManager.sol";

/// @title MockKYCManager
/// @notice Mock implementation of IKYCManager for testing purposes
contract MockKYCManager is IKYCManager {
    // Mapping to track KYC approval status for each address (used by setKYCApproved)
    mapping(address => bool) public approved;
    mapping(address => bool) public isBlacklisted;

    // Global approval flag (used by setApproval and isKYCApproved)
    bool private globalApproved = true;

    /// @notice Set KYC approval status for a specific user (for fine-grained test control)
    /// @param user The address to set approval for
    /// @param status The KYC approval status (true/false)
    function setKYCApproved(address user, bool status) external {
        approved[user] = status;
    }

    /// @notice Set global KYC approval status (for broad test scenarios)
    /// @param _approved The global approval status (true/false)
    function setApproval(bool _approved) external {
        globalApproved = _approved;
    }

    /// @notice Returns KYC approval status for a user
    /// @dev Returns the global approval flag (for simple tests).
    ///      You can change to `return approved[user];` for address-specific logic.
    function isKYCApproved(address) external view override returns (bool) {
        return globalApproved;
    }

    /// @notice Returns dummy KYC status (always Approved)
    function getKYCStatus(address) external pure override returns (KYCStatus) {
        return KYCStatus.Approved;
    }

   function setBlacklisted(address user, bool status) external {
    isBlacklisted[user] = status;
}
    

    function getKYCData(address realtor)
        external
        view
        override
        returns (
            string memory name,
            string memory email,
            string memory nin,
            string memory phone,
            uint256 submittedAt,
            KYCStatus status
        )
    {
        // Return different mock data based on the realtor address
        if (realtor == address(0x1)) {
            return (
                "John Doe",
                "john@example.com",
                "1234567890",
                "123-456-7890",
                block.timestamp - 86400, // 1 day ago
                KYCStatus.Approved
            );
        } else if (realtor == address(0x2)) {
            return (
                "Jane Smith",
                "jane@example.com",
                "0987654321",
                "098-765-4321",
                block.timestamp - 172800, // 2 days ago
                KYCStatus.Pending
            );
        } else {
            return (
                "Default User", "default@example.com", "5555555555", "555-555-5555", block.timestamp, KYCStatus.Approved
            );
        }
    }

    //    /// @notice Returns dummy KYC data
    // function getKYCData(address realtor)
    //     external
    //     view
    //     override
    //     returns (
    //         string memory name,
    //         string memory email,
    //         string memory nin,
    //         string memory phone,
    //         uint256 submittedAt,
    //         KYCStatus status
    //     )
    // {
    //     return (
    //         "John Doe",           // name
    //         "john@example.com",   // email
    //         "1234567890",         // nin
    //         "123-456-7890",       // phone
    //         block.timestamp,      // submittedAt
    //         KYCStatus.Approved   // status (assuming you have this enum defined)
    //     );
    // }
}
