Brickchain Smart Contracts: Decentralized Property Tokenization 🧱

## Project Overview
This repository contains the core smart contracts for **Brickchain**, a decentralized real estate tokenization platform. Built on Solidity and leveraging the robust Foundry development toolkit, Brickchain enables fractional ownership of properties, secure fund management, and a comprehensive access control system for various stakeholders.

## Features
*   **Access Management**: Implements granular, role-based access control (RBAC) including `ADMIN`, `REALTOR`, `INVESTOR`, `TENANT`, `AUDITOR`, and `TOKEN_ADMIN` roles for secure operations.
*   **KYC Management**: A dedicated system for Know-Your-Customer (KYC) verification, allowing submission, approval, and rejection of user identities to ensure compliance and eligibility.
*   **Property Registry**: Manages the listing and lifecycle of real-world properties, linking them to newly minted fractionalized tokens on-chain.
*   **Property Tokenization**: Creates ERC20-compliant tokens (`PropertyToken`) for each registered property, representing fractional ownership.
*   **Decentralized Escrow**: Provides a secure, auditable mechanism for investors to deposit stablecoins for property token purchases, holding funds until transactions are finalized.
*   **Vault & Vault Management**: A central vault for securely holding and distributing property tokens, managed by a dedicated `VaultManager` for seamless investment settlement.
*   **Price Oracle Integration**: Utilizes Chainlink Price Feeds for accurate and real-time conversion of fiat values (USD) to native blockchain currency (ETH) for listing fees.
*   **Secure Operations**: Incorporates OpenZeppelin's battle-tested contracts for `AccessControl`, `Pausable`, and `ReentrancyGuard` to enhance contract security and emergency response capabilities.

## Getting Started
To get a local copy of the Brickchain smart contracts up and running, follow these steps.

### Installation
You will need Foundry installed on your system. If you don't have it, follow the instructions on the [Foundry Book](https://book.getfoundry.sh/getting-started/installation).

🛠️ **Clone the Repository**:
```bash
git clone https://github.com/ChainBuilders/BrickChain.git
cd BrickChain/contract
```

📦 **Install Foundry Dependencies**:
```bash
forge install
```

⚙️ **Build Contracts**:
```bash
forge build
```

### Environment Variables
The deployment and interaction scripts require specific environment variables to be set. Create a `.env` file in the root of the `contract` directory with the following variables:

```dotenv
PRIVATE_KEY="your_admin_private_key" # Private key of the deployer/admin account
REALTOR_PRIVATE_KEY="your_realtor_private_key" # Private key of a realtor account
ADMIN_ADDRESS="0x..." # Address for the initial admin role
AUDITOR_ADDRESS="0x..." # Address for an auditor role
REALTOR_ADDRESS="0x..." # Address for a realtor role
TOKEN_ADMIN_ADDRESS="0x..." # Address for a token admin role

# Deployed Contract Addresses (these will be set after initial deployments)
ACCESS_MANAGER_ADDRESS="0x..."
KYC_MANAGER_ADDRESS="0x..."
ESCROW_ADDRESS="0x..."
VAULT_ADDRESS="0x..."
TOKEN_FACTORY_ADDRESS="0x..."


# Brickchain Configuration
ADMIN_ADDRESS=0x45630a7Db07604f82a1D2ccf8509eb375b1826C6
REGISTRY_ADDRESS=0xc503662F644aAb33de5Da5CcCcc04902Bd476184
ACCESS_MANAGER_ADDRESS=0xE70aA6Ba5780db1Ccea17FAC520e514B8F72cd06
KYC_MANAGER_ADDRESS=0xaAEA02A014465E2eD733c73b407EFC7cB7FacEBA
TOKEN_FACTORY_ADDRESS=0x5db2D76920f9a059ba835E8d0a17F1c1423B1605
VAULT_ADDRESS=0xecf89B18B8A209Bf1C186FB65162b5ba299C7cF6
ESCROW_ADDRESS=0x1a1352D67463B0F4E660CE1f4eFa5ec6a8F17A10
VAULT_MANAGER_ADDRESS=0xEee22c37de3187Bbf06B1cb128A223E66cfB5196
LISTING_FEE=1000000000000000000
FEE_RECIPIENT_ADDRESS=0x45630a7Db07604f82a1D2ccf8509eb375b1826C6
PRICE_FEED_ADDRESS=0x694AA1769357215DE4FAC081bf1f309aDC325306
STABLECOIN_ADDRESS=0x1c7D4B196Cb0C7B01d064914d4010F4f4a9465bD
AUDITOR_ADDRESS=0x45630a7Db07604f82a1D2ccf8509eb375b1826C6
REALTOR_ADDRESS= # 0xNewRealtor (To be set dynamically)


REGISTRY_ADDRESS="0x..."
VAULT_MANAGER_ADDRESS="0x..."

# Chainlink Price Feed Address (Example for Sepolia ETH/USD)
PRICE_FEED_ADDRESS="0x694AA1769357215DE4FAC081bf1f309aDC325306"

# Stablecoin Address (Example for cNGN on Sepolia, adjust as needed)
STABLECOIN_ADDRESS="0x1C7D4b196Cb0c7b01d064914d4010f4F4a9465bD"

# Registry Configuration
LISTING_FEE=1000000000000000000 # Example: 1 ETH
FEE_RECIPIENT_ADDRESS="0x..." # Address to receive listing fees
```

### Deployment and Interaction
Deploying and interacting with Brickchain involves a sequence of Foundry scripts. Ensure your `.env` file is properly configured with the necessary private keys and RPC URLs.

**Example Deployment Flow (using Foundry scripts):**

1.  **Deploy `AccessManager`**:
    ```bash
    forge script script/DeployAccessManager.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `ACCESS_MANAGER_ADDRESS` in `.env` with the deployed address.*

2.  **Deploy `KYCManager`**:
    ```bash
    forge script script/DeployKYCManager.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `KYC_MANAGER_ADDRESS` in `.env` with the deployed address.*

3.  **Deploy `Escrow`**:
    ```bash
    forge script script/DeployEscrow.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `ESCROW_ADDRESS` in `.env` with the deployed address.*

4.  **Deploy `Vault`**:
    ```bash
    forge script script/DeployVault.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `VAULT_ADDRESS` in `.env` with the deployed address.*

5.  **Deploy `TokenFactory`**:
    ```bash
    forge script script/DeployTokenFactory.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `TOKEN_FACTORY_ADDRESS` in `.env` with the deployed address.*

6.  **Deploy `Registry`**:
    ```bash
    forge script script/DeployRegistry.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `REGISTRY_ADDRESS` in `.env` with the deployed address.*

7.  **Deploy `VaultManager`**:
    ```bash
    forge script script/DeployVaultManager.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```
    *Update `VAULT_MANAGER_ADDRESS` in `.env` with the deployed address.*

8.  **Update Dependencies (Set actual Registry address in Vault & TokenFactory)**:
    ```bash
    forge script script/UpdateDependencies.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

9.  **Grant Roles (Admin grants roles to Auditor & Realtor)**:
    ```bash
    forge script script/GrantRoles.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

10. **Set Stablecoin Status (Admin enables stablecoin in Escrow)**:
    ```bash
    forge script script/SetStablecoinStatus.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

11. **Whitelist VaultManager (Admin whitelists VaultManager in Escrow)**:
    ```bash
    forge script script/WhitelistVaultManager.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

12. **Submit KYC (Realtor submits KYC)**:
    ```bash
    forge script script/SubmitKYC.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

13. **Approve KYC (Admin approves Realtor's KYC)**:
    ```bash
    forge script script/ApproveKyc.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

14. **Register Property (Realtor registers a property)**:
    ```bash
    forge script script/RegisterProperty.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    ```

This sequence demonstrates the full flow of setting up the Brickchain ecosystem and registering a property. Further interactions (e.g., investor deposits, investment finalization) would involve direct calls to the deployed contracts or additional scripts.

## Technologies Used

| Technology    | Category           | Purpose                                  |
| :------------ | :----------------- | :--------------------------------------- |
| **Solidity**  | Smart Contract     | Primary language for contract development|
| **Foundry**   | Development Toolkit| Build system, testing, deployment, fuzzing |
| **OpenZeppelin**| Libraries        | Secure, battle-tested smart contract modules |
| **Chainlink** | Oracle Network     | Decentralized price feeds for real-world data |

## Contributing
We welcome contributions to the Brickchain project! Here's how you can help:

✨ **Fork the repository**: Start by forking the repository to your GitHub account.
🚀 **Create a new branch**: Create a new branch for your feature or bug fix:
```bash
git checkout -b feature/AmazingFeature
```
💻 **Make your changes**: Implement your changes and ensure tests pass.
🧪 **Write tests**: For new features, always include comprehensive tests.
✅ **Commit your changes**: Write clear, concise commit messages.
⬆️ **Push to the branch**: Push your changes to your forked repository.
```bash
git push origin feature/AmazingFeature
```
🔄 **Open a pull request**: Submit a pull request to the `main` branch of the original repository, describing your changes in detail.

## License
No explicit license file was found in the provided project context. Please clarify the intended licensing for contributions and usage.

## Author Info
*   **[Your Name]** - Connect with me on [LinkedIn](YOUR_LINKEDIN_PROFILE) | [Twitter](YOUR_TWITTER_HANDLE)
*   **Email**: YOUR_EMAIL@example.com

## Badges
![Solidity](https://img.shields.io/badge/Solidity-^0.8.24-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Foundry-Framework-informational?logo=foundry&logoColor=white)
[![License: Unlicensed](https://img.shields.io/badge/License-Unlicensed-lightgrey.svg)](https://unlicense.org/) <!-- Generic Unlicense badge if no explicit license file -->
[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)