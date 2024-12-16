//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YourContract is ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => uint256)) private balances;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event EthDeposit(address indexed user, uint256 amount);
    event EthWithdrawal(address indexed user, uint256 amount);
    
    constructor() {}

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(token != address(0), "Invalid token address");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        balances[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(token != address(0), "Invalid token address");
        require(balances[msg.sender][token] >= amount, "Insufficient balance");

        balances[msg.sender][token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "Amount must be greater than zero");

        balances[msg.sender][address(0)] += msg.value;

        emit EthDeposit(msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender][address(0)] >= amount, "Insufficient balance");

        balances[msg.sender][address(0)] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit EthWithdrawal(msg.sender, amount);
    }

    function balanceOf(address user, address token) external view returns (uint256) {
        return balances[user][token];
    }

    function ethBalanceOf(address user) external view returns (uint256) {
        return balances[user][address(0)];
    }
}
