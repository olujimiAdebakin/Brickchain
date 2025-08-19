// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../access/AccessManager.sol";

/// @title PropertyToken
/// @notice Standard ERC20 token representing fractional ownership of a property.
/// @dev NATSEC: Pausing is enforced via AccessManager. KYC/AML is enforced at Vault/Registry level, not here.
contract PropertyToken is ERC20, Ownable {
    AccessManager public accessManager; //  Centralized pause control

    string public propertyName; // Human-readable property name
    string public propertySymbol; // Human-readable property symbol
    string public propertyURI; // Off-chain metadata URI

    /// @notice Constructor mints full supply to the designated owner (Vault or Realtor)
    /// @param accessManagerAddress Address of AccessManager contract (for pause control)
    /// @param name Human-readable property name
    /// @param symbol Human-readable property symbol (e.g. "BRICK1")
    /// @param totalSupply Total tokens to be minted (18 decimals)
    /// @param tokenName ERC20 token name
    /// @param tokenSymbol ERC20 token symbol
    /// @param _propertyURI Off-chain metadata URI
    /// @param owner Address receiving all minted tokens (Vault or Realtor)
    constructor(
        address accessManagerAddress, // ✅ 1
        string memory name, // ✅ 2
        string memory symbol, // ✅ 3
        uint256 totalSupply, // ✅ 4
        string memory tokenName, // ✅ 5
        string memory tokenSymbol, // ✅ 6
        string memory _propertyURI, // ✅ 7
        address owner // ← Tokens minted to this address
            // ✅ 8
    )
        ERC20(tokenName, tokenSymbol)
        Ownable(owner) // Set owner for Ownable functions
    {
        propertyName = name;
        propertySymbol = symbol;
        propertyURI = _propertyURI;
        accessManager = AccessManager(accessManagerAddress);
        _mint(owner, totalSupply); // Mint all tokens to owner (Vault or Realtor)
        _transferOwnership(owner); // Set owner for Ownable functions
    }

    /// @notice Modifier to block transfers if AccessManager is paused (NATSEC)
    modifier whenNotPaused() {
        require(!accessManager.paused(), "Contract is paused");
        _;
    }

    /// @notice Pausing logic for all token transfers (NATSEC standard)
    /// @dev This override ensures that no token transfers, minting, or burning can occur while the contract is paused.
    ///      The `whenNotPaused` modifier checks the central AccessManager's paused state before allowing any transfer.
    ///      This is critical for emergency response, regulatory compliance, and operational security (NATSEC).
    function _update(address from, address to, uint256 amount) internal override whenNotPaused {
        // Calls the parent ERC20 hook to maintain standard transfer logic.
        // All transfer, mint, and burn operations are blocked if paused.
        super._update(from, to, amount);
    }

    /// @notice Allows owner to update property metadata URI
    function setPropertyURI(string memory _propertyURI) external onlyOwner {
        propertyURI = _propertyURI;
    }

    /// @notice Returns the AccessManager address (for transparency)
    function getAccessManager() external view returns (address) {
        return address(accessManager);
    }
}
