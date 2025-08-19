// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/interfaces/IEscrow.sol";

contract MockEscrow is IEscrow {
    uint256 public lastPropertyId;
    address public lastInvestor;
    address public lastStablecoin;
    uint256 public lastAmount;
    address public lastRecipient;

    mapping(address => mapping(uint256 => mapping(address => uint256))) public deposits;

    function setDeposit(address investor, uint256 propertyId, address stablecoin, uint256 amount) external {
        deposits[investor][propertyId][stablecoin] = amount;
    }

    function getDeposit(address investor, uint256 propertyId, address stablecoin)
        external
        view
        override
        returns (uint256)
    {
        return deposits[investor][propertyId][stablecoin];
    }

    function withdrawTo(uint256 propertyId, address investor, address stablecoin, uint256 amount, address recipient)
        external
        override
    {
        lastPropertyId = propertyId;
        lastInvestor = investor;
        lastStablecoin = stablecoin;
        lastAmount = amount;
        lastRecipient = recipient;
        deposits[investor][propertyId][stablecoin] = 0;
    }

    function deposit(uint256, address, uint256) external override {}
    function setStablecoinStatus(address, bool) external override {}
    function setStablecoinStatusByBatch(address[] calldata, bool[] calldata) external override {}

    function isStablecoinAccepted(address) external view override returns (bool) {
        return true;
    }
}
