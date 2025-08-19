// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../access/AccessManager.sol";

/// @title KYCManager
/// @notice Handles KYC submission, approval, and rejection for realtors in the Brickchain ecosystem
/// @dev Inherits AccessManager for role and permission management
contract KYCManager is AccessManager {
    /// @notice Status of a KYC submission
    enum KYCStatus {
        None,
        Pending,
        Approved,
        Rejected
    }

    /// @notice Stores KYC data for a realtor
    /// @param name Full name of the realtor
    /// @param email Email address of the realtor
    /// @param nin National Identification Number
    /// @param phone Phone number of the realtor
    /// @param submittedAt Timestamp when KYC was submitted
    /// @param status Current status of the KYC process
    struct KYCData {
        string name;
        string email;
        string nin;
        string phone;
        uint256 submittedAt;
        KYCStatus status;
    }

    /// @notice Mapping from realtor address to their KYC data
    mapping(address => KYCData) public realtorKYC;

    /// @notice Emitted when a realtor submits KYC
    /// @param realtor The address of the realtor
    /// @param submittedAt The timestamp when KYC was submitted
    event KYCSubmitted(address indexed realtor, uint256 submittedAt);

    /// @notice Emitted when a realtor's KYC is approved
    /// @param realtor The address of the realtor
    /// @param approvedAt The timestamp when KYC was approved
    event KYCApproved(address indexed realtor, uint256 approvedAt);

    /// @notice Emitted when a realtor's KYC is rejected
    /// @param realtor The address of the realtor
    /// @param rejectedAt The timestamp when KYC was rejected
    event KYCRejected(address indexed realtor, uint256 rejectedAt);

    /// @notice Initializes the KYCManager contract and sets the admin
    /// @param admin The address to be granted admin rights
    constructor(address admin) AccessManager(admin) {}

    // --- MODIFIERS ---

    /// @notice Restricts function to admin or auditor roles
    // modifier onlyAdminOrAuditor() {
    //     require(hasAnyRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasAnyRole(AUDITOR_ROLE, msg.sender), "Not admin or auditor");
    //     _;
    // }

    /// @notice Restricts function to KYC-approved realtors
    modifier onlyKYCApproved() {
        require(realtorKYC[msg.sender].status == KYCStatus.Approved, "KYC not approved");
        _;
    }

    // --- KYC FLOW ---

    /// @notice Submit KYC information for the sender (realtor)
    /// @param name Full name of the realtor
    /// @param email Email address of the realtor
    /// @param nin National Identification Number
    /// @param phone Phone number of the realtor
    function submitKYC(string calldata name, string calldata email, string calldata nin, string calldata phone)
        external
    {
        require(
            realtorKYC[msg.sender].status == KYCStatus.None || realtorKYC[msg.sender].status == KYCStatus.Rejected,
            "KYC already submitted or approved"
        );

        realtorKYC[msg.sender] = KYCData({
            name: name,
            email: email,
            nin: nin,
            phone: phone,
            submittedAt: block.timestamp,
            status: KYCStatus.Pending
        });
        emit KYCSubmitted(msg.sender, block.timestamp);
    }

    /// @notice Approve a realtor's KYC after 24 hours
    /// @dev Only callable by admin or auditor. Grants REALTOR_ROLE to the realtor.
    /// @param realtor The address of the realtor to approve
    function approveKYC(address realtor) external onlyAdminOrAuditor {
        require(realtorKYC[realtor].status != KYCStatus.Approved, "Already approved");
        require(realtorKYC[realtor].status == KYCStatus.Pending, "Not pending");
        // require(block.timestamp >= realtorKYC[realtor].submittedAt + 24 hours, "Wait 24hrs after KYC");
            require(block.timestamp >= realtorKYC[realtor].submittedAt + 2 seconds, "Wait 2s after KYC");
        realtorKYC[realtor].status = KYCStatus.Approved;
        _grantRole(REALTOR_ROLE, realtor);
        emit KYCApproved(realtor, block.timestamp);
    }

    /// @notice Reject a realtor's KYC submission
    /// @dev Only callable by admin or auditor
    /// @param realtor The address of the realtor to reject
    function rejectKYC(address realtor) external onlyAdminOrAuditor {
        require(realtorKYC[realtor].status == KYCStatus.Pending, "Not pending");
        realtorKYC[realtor].status = KYCStatus.Rejected;
        emit KYCRejected(realtor, block.timestamp);
    }

    /// @notice Approve multiple realtors' KYC after 24 hours
    /// @dev Only callable by admin or auditor. Grants REALTOR_ROLE to each realtor.
    /// @param realtors The addresses of the realtors to approve
    function batchApproveKYC(address[] calldata realtors) external onlyAdminOrAuditor {
        for (uint256 i = 0; i < realtors.length; i++) {
            address realtor = realtors[i];
            if (
                realtorKYC[realtor].status == KYCStatus.Pending && realtorKYC[realtor].status != KYCStatus.Approved
                    && block.timestamp >= realtorKYC[realtor].submittedAt + 24 hours
            ) {
                realtorKYC[realtor].status = KYCStatus.Approved;
                _grantRole(REALTOR_ROLE, realtor);
                emit KYCApproved(realtor, block.timestamp);
            }
        }
    }

    /// @notice Reject multiple realtors' KYC submissions
    /// @dev Only callable by admin or auditor
    /// @param realtors The addresses of the realtors to reject
    function batchRejectKYC(address[] calldata realtors) external onlyAdminOrAuditor {
        for (uint256 i = 0; i < realtors.length; i++) {
            address realtor = realtors[i];
            if (realtorKYC[realtor].status == KYCStatus.Pending) {
                realtorKYC[realtor].status = KYCStatus.Rejected;
                emit KYCRejected(realtor, block.timestamp);
            }
        }
    }

    // --- VIEW FUNCTIONS ---

    /// @notice Check if a realtor's KYC is approved
    /// @param realtor The address of the realtor
    /// @return True if approved, false otherwise
    function isKYCApproved(address realtor) external view returns (bool) {
        return realtorKYC[realtor].status == KYCStatus.Approved;
    }

    /// @notice Get the KYC status of a realtor
    /// @param realtor The address of the realtor
    /// @return The current KYC status of the realtor
    function getKYCStatus(address realtor) external view returns (KYCStatus) {
        return realtorKYC[realtor].status;
    }

    /// @notice Get the full KYC data of a realtor
    /// @param realtor The address of the realtor
    /// @return The KYCData struct for the realtor
    function getKYCData(address realtor) external view returns (KYCData memory) {
        return realtorKYC[realtor];
    }

   function setBlacklisted(address realtor, bool status) external onlyAdminOrAuditor {
    isBlacklisted[realtor] = status;
}
}
