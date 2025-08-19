// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockAccessManager {
    bool public pausedState;

    function pause() external {
        pausedState = true;
    }

    function unpause() external {
        pausedState = false;
    }

    function paused() external view returns (bool) {
        return pausedState;
    }
}
