
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/escrow/Escrow.sol";

contract SetStablecoinStatus is Script {
    /// @notice Sets stablecoin status in Escrow
    /// @dev Enables the specified stablecoin for deposits
    function run() external {
        bytes32 deployerPrivateKey = vm.envBytes32("PRIVATE_KEY");
        address deployer = vm.addr(uint256(deployerPrivateKey));
        console.log("Deployer address:", deployer);

        address escrow = vm.envAddress("ESCROW_ADDRESS");
        address stablecoin = vm.envAddress("STABLECOIN_ADDRESS");
        console.log("Escrow address:", escrow);
        console.log("Stablecoin address:", stablecoin);

        require(escrow != address(0), "Invalid Escrow address");
        require(stablecoin != address(0), "Invalid stablecoin address");

        vm.startBroadcast(uint256(deployerPrivateKey));
        Escrow(escrow).setStablecoinStatus(stablecoin, true);
        console.log("Stablecoin enabled in Escrow:", stablecoin);
        vm.stopBroadcast();

        console.log("Stablecoin status set by:", deployer);
    }
}