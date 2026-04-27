// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // 1. How do we send ETH to this contract
    // How we can change ETH to USD -> Use chainlink oracle
    // To change ETH to USD on Sepolia Testnet, we need two thing
        // Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306 
            // -> Intead of harding core, we will use priceFeed variable
        // ABI
        // To get Address 
            // Access to: docs.chain.link -> Data Feed 
            // Price Feeds -> Sepolia Testnet -> ETH / USD
        // To get ABI
            // Compile AggregatorV3Interface on chainlink github
    // Get price 1ETH to USD
    // Why we need to return uint256(price * 1e10)
        // On chainlink (Chainlink's Decimal)
            // When we call latestRoundData() on ETH/USD price feed
            // It will return the current price of ETH, but it returns it with 8 decimal places
            // This means if 1ETH = $2000 -> It will return 2000_00000000 (2000 + 8 zeros)
        // On Ethereum (Ethereum's Decimal)
            // msg.value is always meansured by wei (1ETH = 1e18 wei)
        // To match uint between Chainlink and Ethereum
            // The price which Chainlink returns will need more 10 zeros after it
            // That means: 1ETH = 1e18 wei = uint256(price * 1e10)
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        // latestRoundData() -> return 5 things
        // (roundId, answer, startedAt, updatedAt, answeredInRound)
        // We want answer which is the price
        (,int256 price,,,) = priceFeed.latestRoundData();
        // Price of ETH in terms of USD
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        // ethPrice = $2000 = 2000_00000000_0000000000 = 2000 * 1e18 wei
        // ethAmount = 1 ETH = 1e18 wei
        uint256 ethPrice = getPrice(priceFeed);
        // etheAmountInUsd = 2000 * 1e38 / 1e18 = 2000 * 1e18 = $2000
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18; 
        return ethAmountInUsd;
    }
}

