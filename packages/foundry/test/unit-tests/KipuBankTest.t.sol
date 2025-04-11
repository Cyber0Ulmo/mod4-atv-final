// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {KipuBank} from "../../contracts/KipuBank.sol";

contract KipuBankTest is Test {
    // Instances
    KipuBank bank;

    // Users
    address Barba = makeAddr("Barba");
    address student1 = makeAddr("student1");
    address student2 = makeAddr("student2");

    // Constants
    uint256 constant BANK_CAP = 10*10**18;
    uint256 constant INITIAL_BALANCE = 100*10**18;

    modifier processDeposit() {
        uint256 amount = 1*10**18;
        vm.prank(Barba);
        bank.deposit{value: amount}();
        _;
    }

    function setUp() public {
        bank = new KipuBank(BANK_CAP);

        vm.deal(Barba, INITIAL_BALANCE);
        vm.deal(student1, INITIAL_BALANCE);
        vm.deal(student2, INITIAL_BALANCE);
    }

    // Tests
    function test_depositPass() public {
        vm.prank(Barba);
        vm.expectEmit();
        emit KipuBank.Deposit(Barba, 1 ether);
        bank.deposit{value: 1 ether}();
        assertEq(address(bank).balance, 1 ether);
    }

    function test_depositUpdatesBalance() public {
        vm.prank(Barba);
        bank.deposit{value: 2 ether}();
        assertEq(bank.s_balances(Barba), 2 ether);
    }

    function test_depositExceedsCapReverts() public {
        // Force contract balance over cap
        vm.deal(address(bank), BANK_CAP + 1);
        vm.prank(Barba);
        vm.expectRevert(KipuBank.KipuBank_DepositExceedsCap.selector);
        bank.deposit{value: 1 ether}();
    }

    function test_receiveFunctionReverts() public {
    vm.expectRevert("Use deposit function");
    address(bank).call{value: 1 ether}("");
    }


    function test_withdrawPass() public processDeposit {
        vm.prank(Barba);
        vm.expectEmit();
        emit KipuBank.Withdraw(Barba, 1 ether);
        bank.withdraw(1 ether);
        assertEq(address(bank).balance, 0);
    }

    function test_withdrawUpdatesBalance() public processDeposit {
        uint256 initialBalance = bank.s_balances(Barba);
        vm.prank(Barba);
        bank.withdraw(1 ether);
        assertEq(bank.s_balances(Barba), initialBalance - 1 ether);
    }

    function test_withdrawExceedsLimitReverts() public {
        // Create bank with higher cap for this test
        KipuBank highCapBank = new KipuBank(200 ether);
        vm.deal(Barba, 200 ether);
        
        vm.prank(Barba);
        highCapBank.deposit{value: 101 ether}();
        
        vm.prank(Barba);
        vm.expectRevert(KipuBank.KipuBank_ExceedsWithdrawLimit.selector);
        highCapBank.withdraw(101 ether);
    }

    function test_withdrawTransferFailed() public processDeposit {
        // Create malicious contract without receive function
        MaliciousUser maliciousUser = new MaliciousUser();
        vm.deal(address(maliciousUser), INITIAL_BALANCE);

        // Deposit from malicious user
        vm.prank(address(maliciousUser));
        bank.deposit{value: 1 ether}();

        // Attempt withdraw to contract without receive
        vm.prank(address(maliciousUser));
        vm.expectRevert(KipuBank.KipuBank_TransferFailed.selector);
        bank.withdraw(1 ether);
    }

    function test_multipleDepositsExceedingCap() public {
    vm.prank(student1);
    bank.deposit{value: 4 ether}();
    
    vm.prank(student2);
    bank.deposit{value: 5 ether}();
    
    vm.prank(Barba);
    bank.deposit{value: 1 ether}();  
    
    // should revert
    vm.prank(student1);
    vm.expectRevert(KipuBank.KipuBank_DepositExceedsCap.selector);
    bank.deposit{value: 1 ether}();
    }


    function test_getContractBalance() public processDeposit {
        assertEq(bank.getContractBalance(), 1 ether);
    }

    error KipuBank_InsufficientBalance();
    function test_withdrawFail() public processDeposit {
        vm.prank(Barba);
        vm.expectRevert(abi.encodeWithSelector(
            KipuBank.KipuBank_InsufficientBalance.selector
        ));
        bank.withdraw(2 ether);
    }
}

contract MaliciousUser {
    // No receive or fallback functions
    function deposit(KipuBank bank) external payable {
        bank.deposit{value: msg.value}();
    }
    function withdraw(KipuBank bank, uint256 amount) external {
        bank.withdraw(amount);
    }
}