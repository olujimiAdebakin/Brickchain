// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/vault/Vault.sol";

contract MockVault is Vault {
    struct AdminInvestCall {
        uint256 propertyId;
        address investor;
        address stablecoin;
        uint256 amount;
        address realtor;
        uint256 timestamp;
        address calledBy;
    }

    AdminInvestCall[] public adminInvestCalls;

    uint256 public lastPropertyId;
    address public lastInvestor;
    address public lastStablecoin;
    uint256 public lastAmount;
    address public lastRealtor;

    bool public adminInvestCalled;
    uint256 public adminInvestCallCount;
    uint256 public lastCallTimestamp;

    event TestLog(
        uint256 indexed propertyId,
        address indexed investor,
        address stablecoin,
        uint256 amount,
        address indexed realtor,
        address calledBy,
        uint256 timestamp
    );

    constructor(address admin, address kycManager, address registry, address stablecoin)
        Vault(admin, kycManager, registry, stablecoin)
    {
        // _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function adminInvest(uint256 propertyId, address investor, address stablecoin, uint256 amount, address realtor)
        external
        // override
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        // Track last call data
        lastPropertyId = propertyId;
        lastInvestor = investor;
        lastStablecoin = stablecoin;
        lastAmount = amount;
        lastRealtor = realtor;

        // Track call metadata
        adminInvestCalled = true;
        adminInvestCallCount += 1;
        lastCallTimestamp = block.timestamp;

        // Save full call to array
        adminInvestCalls.push(
            AdminInvestCall({
                propertyId: propertyId,
                investor: investor,
                stablecoin: stablecoin,
                amount: amount,
                realtor: realtor,
                timestamp: block.timestamp,
                calledBy: msg.sender
            })
        );

        // Emit test log event
        emit TestLog(propertyId, investor, stablecoin, amount, realtor, msg.sender, block.timestamp);
    }

    // Utility to get the latest call details
    function getLastCall() external view returns (AdminInvestCall memory) {
        return adminInvestCalls[adminInvestCalls.length - 1];
    }
}
