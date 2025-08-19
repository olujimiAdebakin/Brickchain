// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IKYCManager
/// @notice Interface for interacting with the KYCManager contract
interface IKYCManager {
    /// @notice Status of a KYC submission
    enum KYCStatus {
        None,
        Pending,
        Approved,
        Rejected
    }

    /// @notice Check if a realtor's KYC is approved
    /// @param realtor The address of the realtor
    /// @return True if approved, false otherwise
    function isKYCApproved(address realtor) external view returns (bool);

    /// @notice Get the KYC status of a realtor
    /// @param realtor The address of the realtor
    /// @return The current KYC status of the realtor
    function getKYCStatus(address realtor) external view returns (KYCStatus);

    /// @notice Get the full KYC data of a realtor
    /// @param realtor The address of the realtor
    /// @return name Full name of the realtor
    /// @return email Email address of the realtor
    /// @return nin National Identification Number
    /// @return phone Phone number of the realtor
    /// @return submittedAt Timestamp when KYC was submitted
    /// @return status Current status of the KYC process
    function getKYCData(address realtor)
        external
        view
        returns (
            string memory name,
            string memory email,
            string memory nin,
            string memory phone,
            uint256 submittedAt,
            KYCStatus status
        );
}
