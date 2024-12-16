// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/YourContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract MaliciousReentrant {
    YourContract public targetContract;
    address public tokenAddress;
    uint256 public attackAmount;

    constructor(YourContract _targetContract, address _tokenAddress) {
        targetContract = _targetContract;
        tokenAddress = _tokenAddress;
    }

    function attack(uint256 _amount) external {
        attackAmount = _amount;
        targetContract.depositETH{value: _amount}();
        targetContract.withdrawETH(_amount);
    }

    receive() external payable {
        if (address(targetContract).balance >= attackAmount) {
            targetContract.withdrawETH(attackAmount);
        }
    }
}

contract YourContractTest is Test {
    YourContract public yourContract;
    MockERC20 public mockToken;
    address public user;
    address public otherUser;

    function setUp() public {
        user = vm.addr(1);
        otherUser = vm.addr(2);

        vm.label(user, "User");
        vm.label(otherUser, "Other User");

        yourContract = new YourContract();
        mockToken = new MockERC20("Mock Token", "MTK", 1_000_000 ether);

        mockToken.transfer(user, 1000 ether);
        mockToken.transfer(otherUser, 1000 ether);

        vm.deal(user, 100 ether);
        vm.deal(otherUser, 100 ether);
    }

    function testTokenDeposit() public {
        vm.startPrank(user);

        mockToken.approve(address(yourContract), 100 ether);
        yourContract.deposit(address(mockToken), 100 ether);

        uint256 balance = yourContract.balanceOf(user, address(mockToken));
        assertEq(balance, 100 ether);

        vm.stopPrank();
    }

    function testTokenWithdrawal() public {
        vm.startPrank(user);

        mockToken.approve(address(yourContract), 100 ether);
        yourContract.deposit(address(mockToken), 100 ether);

        yourContract.withdraw(address(mockToken), 50 ether);

        uint256 balance = yourContract.balanceOf(user, address(mockToken));
        assertEq(balance, 50 ether);

        uint256 userTokenBalance = mockToken.balanceOf(user);
        assertEq(userTokenBalance, 950 ether);

        vm.stopPrank();
    }

    function testEthDeposit() public {
        vm.startPrank(user);

        yourContract.depositETH{value: 10 ether}();

        uint256 balance = yourContract.ethBalanceOf(user);
        assertEq(balance, 10 ether);

        vm.stopPrank();
    }

    function testEthWithdrawal() public {
        vm.startPrank(user);

        yourContract.depositETH{value: 10 ether}();

        yourContract.withdrawETH(5 ether);

        uint256 balance = yourContract.ethBalanceOf(user);
        assertEq(balance, 5 ether);

        uint256 userEthBalance = user.balance;
        assertEq(userEthBalance, 95 ether);

        vm.stopPrank();
    }

    function testInsufficientTokenWithdrawal() public {
        vm.startPrank(user);

        mockToken.approve(address(yourContract), 50 ether);
        yourContract.deposit(address(mockToken), 50 ether);

        vm.expectRevert("Insufficient balance");
        yourContract.withdraw(address(mockToken), 100 ether);

        vm.stopPrank();
    }

    function testInsufficientEthWithdrawal() public {
        vm.startPrank(user);

        yourContract.depositETH{value: 5 ether}();

        vm.expectRevert("Insufficient balance");
        yourContract.withdrawETH(10 ether);

        vm.stopPrank();
    }

    function testZeroAmountTokenDeposit() public {
        vm.startPrank(user);

        vm.expectRevert("Amount must be greater than zero");
        yourContract.deposit(address(mockToken), 0);

        vm.stopPrank();
    }

    function testZeroAmountEthDeposit() public {
        vm.startPrank(user);

        vm.expectRevert("Amount must be greater than zero");
        yourContract.depositETH{value: 0}();

        vm.stopPrank();
    }

    function testZeroAddressTokenDeposit() public {
        vm.startPrank(user);

        vm.expectRevert("Invalid token address");
        yourContract.deposit(address(0), 100 ether);

        vm.stopPrank();
    }

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event EthDeposit(address indexed user, uint256 amount);
    event EthWithdrawal(address indexed user, uint256 amount);

    function testEventEmissions() public {
        vm.startPrank(user);

        mockToken.approve(address(yourContract), 100 ether);

        vm.expectEmit(true, true, false, true);
        emit Deposit(user, address(mockToken), 100 ether);
        yourContract.deposit(address(mockToken), 100 ether);

        vm.expectEmit(true, true, false, true);
        emit Withdrawal(user, address(mockToken), 50 ether);
        yourContract.withdraw(address(mockToken), 50 ether);

        vm.expectEmit(true, false, false, true);
        emit EthDeposit(user, 10 ether);
        yourContract.depositETH{value: 10 ether}();

        vm.expectEmit(true, false, false, true);
        emit EthWithdrawal(user, 5 ether);
        yourContract.withdrawETH(5 ether);

        vm.stopPrank();
    }

    function testBalanceTracking() public {
        vm.startPrank(user);

        mockToken.approve(address(yourContract), 200 ether);
        yourContract.deposit(address(mockToken), 200 ether);
        yourContract.depositETH{value: 20 ether}();

        uint256 tokenBalance = yourContract.balanceOf(user, address(mockToken));
        uint256 ethBalance = yourContract.ethBalanceOf(user);

        assertEq(tokenBalance, 200 ether);
        assertEq(ethBalance, 20 ether);

        yourContract.withdraw(address(mockToken), 100 ether);
        yourContract.withdrawETH(10 ether);

        tokenBalance = yourContract.balanceOf(user, address(mockToken));
        ethBalance = yourContract.ethBalanceOf(user);

        assertEq(tokenBalance, 100 ether);
        assertEq(ethBalance, 10 ether);

        vm.stopPrank();
    }

    function testMultipleUsers() public {
        vm.startPrank(user);

        mockToken.approve(address(yourContract), 100 ether);
        yourContract.deposit(address(mockToken), 100 ether);
        yourContract.depositETH{value: 10 ether}();

        vm.stopPrank();

        vm.startPrank(otherUser);

        mockToken.approve(address(yourContract), 200 ether);
        yourContract.deposit(address(mockToken), 200 ether);
        yourContract.depositETH{value: 20 ether}();

        vm.stopPrank();

        uint256 userTokenBalance = yourContract.balanceOf(user, address(mockToken));
        uint256 userEthBalance = yourContract.ethBalanceOf(user);

        uint256 otherUserTokenBalance = yourContract.balanceOf(otherUser, address(mockToken));
        uint256 otherUserEthBalance = yourContract.ethBalanceOf(otherUser);

        assertEq(userTokenBalance, 100 ether);
        assertEq(userEthBalance, 10 ether);

        assertEq(otherUserTokenBalance, 200 ether);
        assertEq(otherUserEthBalance, 20 ether);
    }

    function testReentrancyGuard() public {
        vm.startPrank(user);

        MaliciousReentrant malicious = new MaliciousReentrant(yourContract, address(mockToken));

        vm.deal(user, 100 ether);

        vm.expectRevert();
        malicious.attack(10 ether);

        vm.stopPrank();
    }
}
