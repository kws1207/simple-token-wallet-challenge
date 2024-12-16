## Overview

The design allows users to:

- Deposit and withdraw **ERC20 tokens** and **Ether**.
- Track individual token and Ether balances.
- Ensure security through input validation and protection against reentrancy attacks.
- Emit events for all transactions for transparency.

## Features

### 1. Deposit Functionality

- **ERC20 Token Deposit**

    ```solidity
    function deposit(address token, uint256 amount) external {
        // Users can deposit ERC20 tokens into their wallet
    }
    ```

- **Ether Deposit**

    ```solidity
    function depositETH() external payable nonReentrant {
        // Users can deposit Ether into their wallet
    }
    ```

### 2. Withdrawal Mechanism

- **ERC20 Token Withdrawal**

    ```solidity
    function withdraw(address token, uint256 amount) external {
        // Users can withdraw their ERC20 tokens
    }
    ```

- **Ether Withdrawal**

    ```solidity
    function withdrawETH(uint256 amount) external nonReentrant {
        // Users can withdraw their Ether
    }
    ```

### 3. Balance Tracking

- **Token Balances**

    ```solidity
    mapping(address => mapping(address => uint256)) private balances;
    ```

    - Tracks each user's balance for every ERC20 token by mapping their address to the token address and balance.

- **Ether Balances**

    - Ether balances are stored using `address(0)` as the token address.

### 4. Security Measures

- **Reentrancy Protection**

    - Uses OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks on functions handling Ether.

- **Safe Token Operations**

    - Uses `SafeERC20` library for safe interactions with ERC20 tokens.

- **Input Validation**

    - Ensures all deposit and withdrawal amounts are greater than zero.
    - Validates token addresses are not zero addresses.

### 5. Event Handling

- Emits events for all deposits and withdrawals:

    ```solidity
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event EthDeposit(address indexed user, uint256 amount);
    event EthWithdrawal(address indexed user, uint256 amount);
    ```

## Testing

To ensure the contract functions as expected, tests have been written and can be found in the `YourContract.t.sol` file. These tests cover scenarios including:

- Token and Ether deposits and withdrawals.
- Balance tracking for multiple users.
- Security checks against reentrancy attacks.
- Event emissions for all transactions.

To run the tests, execute the following command:
```bash
cd packages/foundry
forge test
```
