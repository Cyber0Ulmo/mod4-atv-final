// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract KipuBank {
    // State variables

    // Bank cap
    uint256 public immutable i_bankCap; 
    
    // Withdraw limit
    uint256 public constant WITHDRAW_LIMIT = 100 ether;

    // Mapping for user balances
    // Key: _wallet (address), Value: _amount (uint256)
    mapping(address => uint256) public s_balances; 

    // Events
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    // Erros
    error KipuBank_InsufficientBalance();
    error KipuBank_ExceedsWithdrawLimit();
    error KipuBank_DepositExceedsCap();
    error KipuBank_TransferFailed();
    
    // Constructor
    constructor(uint256 bankCap) {
        i_bankCap = bankCap;
    }
    // receive() function to receive ETH
    receive() external payable {
        revert("Use deposit function");
    }

    // Modifier to check if the deposit does not exceed the bank cap
    modifier checkDepositLimit(uint256 depositAmount) {
        if (address(this).balance > i_bankCap) {
            revert KipuBank_DepositExceedsCap();
        }
        _;
    }

    // Modifier to check if the user has enough balance to withdraw
    modifier checkSufficientBalance(uint256 amount) {
        if (s_balances[msg.sender] < amount) {
            revert KipuBank_InsufficientBalance();
        }
        _;
    }

    // Modifier to check if the withdrawal does not exceed the limit
    modifier checkWithdrawLimit(uint256 amount) {
        if (amount > WITHDRAW_LIMIT) {
            revert KipuBank_ExceedsWithdrawLimit();
        }
        _;
    }
    
    // Internal function to transfer ETH to the user
    function _transferETH(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        
        if (!success) {
            revert KipuBank_TransferFailed();
        }
    }

    // Deposit function
    function deposit() external payable checkDepositLimit(msg.value) {
        
        // Update user balance (_wallet: msg.sender, _amount: msg.value)
        s_balances[msg.sender] += msg.value;

        // Emit deposit event
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw function
    function withdraw(uint256 amount) external 
        checkWithdrawLimit(amount)
        checkSufficientBalance(amount) {
        // Update balance before transfer (_wallet: msg.sender, _amount: amount)
        s_balances[msg.sender] -= amount;

        // Call internal transfer function to send ETH to user
        _transferETH(msg.sender, amount);

        // Emit withdrawal event
        emit Withdraw(msg.sender, amount);
    }

    // Function  contract's ETH balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}