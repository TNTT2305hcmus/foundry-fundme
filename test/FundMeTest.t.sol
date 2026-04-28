// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// We can see "console" more on: getfoundry.sh/forge-std/console
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

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
        assertEq(fundMe.I_OWNER(), msg.sender);
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

    function testFundUpdatesFundedDataStructure() public {
        // The next transaction will be sent by USER
        vm.prank(USER);
        // If we don't have vm.prank(), the transaction will be sent by this smart contract
        fundMe.fund{value: 10e18}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 10e18);
    }

    function testAddsFunderToFunders() public {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();

        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    // forge coverage
    // Foundry analyzes your smart contracts to see exactly how much of our code
    // was actually executed during forge test run.
}
