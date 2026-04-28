// SPDX-License-Identifier: MIT

// If we don't connect with sepolia network, the testPriceFeedVersionIsAccurate will fail.
// Why it fails when we run "forge test -vv" but will pass if we connect to Sepolia network
// forge test -vv
// When it boots up, there is nothing (no tokens, no history, no other smart contracts)
// The only things that exist are the contracts we explicitly deploy inside our setUp()
// When DeployFundMe script tells FundMe that the Chainlink price feed lives at the address (0x694AA1769357215DE4FAC081bf1f309aDC325306)
// There's nothing here, so EVM finds nothing, no contract to talk to, and it crashes
// forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL
// Foundry connects our Alchemy node and downloads a perfect, real-time snapshot of live Sepolia testnet
// When script point to the Chainlink price feed address, It's actual Chainlink AggregatorV3Interface smart contract

// So we need to create this file to pass the test even though we are on local network
// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chain

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deplou mocks
    // Otherwise, grab the existing address from the live network

    // For set up the rules of the fake oracle
    // DECIMAL = 8 : Chainlink's USD price feed always return values with 8 decimal places
    // INITIAL_PRICE = 2000e8 : When smart contract asks the price of ETH, return $2000 USD = 2000 with 8 decimals
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        // We can research chainid at: https://chainlist.org/
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Because we don't have Chainlink price feed before on local anvil network
        // So we need to create and broadcast an address (Chainlink price feed address)
        // before we call it in FundMeTest
        // First, we create folder mocks in folder test, inside it
        // writing a .sol file that based on FluxAggregator contract

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
