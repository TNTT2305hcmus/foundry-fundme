// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// To decrease gas
// We can use "constant" or "immutable"
// constant -> We can add to some variables don't have to be changed forever like "MINIMUM_USD"
// immutable -> We can add to some variables ... like "i_owner"
// We can custom err instead of reverting a string in require()

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // $5
    uint256 public constant MINIMUM_USD = 5 * 1e18;
    // 21,415 gas - constant -> 21,415 * 141000000000 = $9.0585..
    // 23,515 gas - non-constant -> 23,515 * 141000000000 = $9.9468..

    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    address private immutable I_OWNER;
    // 21,508 gas - immutable
    // 23,644 - non-immutable

    AggregatorV3Interface private s_priceFeed;

    constructor(address _priceFeed) {
        I_OWNER = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // _; this means add whatever else you want to do in the function after require
    modifier onlyOwner() {
        // require(msg.sender == owner, "Sener is not owner");
        if (msg.sender != I_OWNER) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getOwner() public view returns (address) {
        return I_OWNER;
    }

    function fund() public payable {
        // Alow user to send $
        // Have a minimun sent $5
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // To save more gas, we SSLOAD s_funder.length only 1 times
        uint256 s_fundersLength = s_funders.length;
        for (uint256 id = 0; id < s_fundersLength; id++) {
            address funder = s_funders[id];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Three different ways to transfer ETH. They include:
        // transfer -> the simplest and at surface level to use
        // msg.sender is address
        // payable(msg.sender) is payable address -> Only this can transfer token
        // It requires 2300 gas and throws error (automatically revert)
        // payable( msg.sender).transfer(address(this).balance);
        // send
        // It requires 2300 gas and returns bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call -> lower level to use -> Incentively use
        // It fowards all gas or sets gas and returns (bool, bytes)
        // In call(""), we can call any functions in Ethereum -> But we will learn later
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // What happen if someone sends this contract ETH without calling the fund function -> We use special function
    // Other people only need to send ETH from Metamask wallets or something like this instead of calling fund()
    // Special function -> It doesn't have to have keyword "function"
    // Explain more: https://solidity-by-example.org/fallback/
    // receive()
    // Only be triggered when CALLDATA is blank
    receive() external payable {
        fund();
    }

    // fallback()
    // We have to define fallback() if we want to send CALLDATA with transaction
    fallback() external payable {
        fund();
    }

    // Ether is sent to contract follow:
    //          is msg.data empty ?
    //              /   \
    //             Y     N
    //            /       \
    //      receive()?   fallback()
    //        /  \
    //       Y    N
    //      /      \
    //  receive() fallback()

    function getAddressToAmountFunded(
        address funderAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[funderAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }
}
