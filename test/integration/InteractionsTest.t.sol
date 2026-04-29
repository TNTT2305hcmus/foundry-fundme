// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Fund, Withdraw} from "../../script/Interactions.s.sol";

contract InteractionTest is Test {
    FundMe fundMe;
    address USER = makeAddr("ThanhDepTrai");
    uint256 constant BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();
        _;
    }

    function testUserCanFundInteractions() public funded {
        Fund fund = new Fund();
        fund.fund(address(fundMe));

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testUserCanWithdrawInteractions() public funded {
        Withdraw withdraw = new Withdraw();
        withdraw.withdraw(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
