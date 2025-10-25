// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract MEVDetectorTrap is ITrap {

    uint256 public constant MIN_MEV_VALUE = 0.1 ether;
    uint256 public constant SIGNIFICANT_MEV_VALUE = 1 ether;
    uint256 public constant CRITICAL_MEV_VALUE = 10 ether;
    uint256 public constant MIN_PRICE_IMPACT = 5;

    struct MEVData {
        address mevBot;
        address victim;
        address token;
        uint256 frontrunAmount;
        uint256 victimAmount;
        uint256 backrunAmount;
        uint256 blockNumber;
        bool isSandwich;
        uint256 priceImpact;
    }

    function collect() external view returns (bytes memory) {
        MEVData memory data = MEVData({
            mevBot: address(0),
            victim: address(0),
            token: address(0),
            frontrunAmount: 0,
            victimAmount: 0,
            backrunAmount: 0,
            blockNumber: block.number,
            isSandwich: false,
            priceImpact: 0
        });
        return abi.encode(data);
    }

    function shouldRespond(bytes[] calldata collectedData)
        external pure returns (bool, bytes memory)
    {
        require(collectedData.length > 0, "No data collected");
        MEVData memory data = abi.decode(collectedData[0], (MEVData));

        if (!data.isSandwich || data.mevBot == address(0)) {
            return (false, bytes(""));
        }

        uint256 extractedValue = calculateExtractedValue(data);

        if (extractedValue >= MIN_MEV_VALUE || data.priceImpact >= MIN_PRICE_IMPACT) {
            return (
                true,
                abi.encode(
                    data.mevBot,
                    data.victim,
                    data.token,
                    data.frontrunAmount,
                    data.victimAmount,
                    data.backrunAmount,
                    data.blockNumber,
                    extractedValue
                )
            );
        }

        return (false, bytes(""));
    }

    function calculateExtractedValue(MEVData memory data)
        internal pure returns (uint256)
    {
        if (data.backrunAmount > data.frontrunAmount) {
            return data.backrunAmount - data.frontrunAmount;
        }
        return 0;
    }

    function getThresholds() external pure returns (uint256, uint256, uint256) {
        return (MIN_MEV_VALUE, SIGNIFICANT_MEV_VALUE, CRITICAL_MEV_VALUE);
    }
}
