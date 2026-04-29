// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// We can see "console" more on: getfoundry.sh/forge-std/console
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    // We can reasearch more cheatcode on: https://getfoundry.sh
    // use vm.prank : which make USER will be the person who send next tx
    // use vm.deal() : which set new balance for new user
    address USER = makeAddr("ThanhDepTrai");
    uint256 constant BALANCE = 10 ether;

    function setUp() external {
        // us -> FundMeTest -> FundMe
        // So the owner of FundMe now is FundMeTest
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, BALANCE);
    }

    function testMininumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // What can we do to work with addresses outside our system
    // Unit
    // Testing a specific part of our code
    // Integration
    // Testing how our code works with other parts of our code
    // Forked
    // Testing our code on a simulated real environment
    // Staging
    // Testing our code in a real environment that is not production

    // New command to test with sepolia network
    // forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    modifier funded() {
        // The next transaction will be sent by USER
        vm.prank(USER);
        // If we don't have vm.prank(), the transaction will be sent by this smart contract
        fundMe.fund{value: 10e18}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 10e18);
    }

    function testAddsFunderToFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    // forge coverage
    // Foundry analyzes your smart contracts to see exactly how much of our code
    // was actually executed during forge test run.

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        // Create two var to track on balance of owner and this contract
        uint256 startOwnerBalance = fundMe.getOwner().balance;
        uint256 startFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endOwnerBalance = fundMe.getOwner().balance;
        uint256 endFundMeBalance = address(fundMe).balance;
        assertEq(endFundMeBalance, 0);
        assertEq(
            startFundMeBalance + startOwnerBalance,
            endFundMeBalance + endOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Instead of call like funded n times
        // We use hoax
        // hoax(address(i), value);
        uint160 numOfFunders = 10;
        // 0 : is funder in modifier funded
        uint160 startFunderIndex = 1;
        for (uint160 i = startFunderIndex; i < numOfFunders; i++) {
            hoax(address(i), 10e18);
            fundMe.fund{value: 10e18}();
        }

        // Now we check
        uint256 startOwnerBalance = fundMe.getOwner().balance;
        uint256 startFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Note (The different between assert() and assertEq())
        // assert(x == y)
        // It's a bulid-in function native in Solidity
        // Used to check for condition
        // It takes a single boolean statement
        // bool false -> throw an err and completely halts the tx
        // assertEq(x, y)
        // It's a specialized testing function in Foundry
        // Make debugging easier for developer
        // It takes two distinct arguments
        // x != y -> Fail and trigger log
        assert(address(fundMe).balance == 0);
        assert(
            startOwnerBalance + startFundMeBalance == fundMe.getOwner().balance
        );

        // We can research more about "chisel", "vm.txgasPrice(x)", "gasleft()"
    }
}
