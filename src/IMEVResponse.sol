// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMEVResponse {
    function recordMEVAlert(
        address mevBot,
        address victim,
        address token,
        uint256 frontrunAmount,
        uint256 victimAmount,
        uint256 backrunAmount,
        uint256 blockNumber,
        uint256 extractedValue
    ) external;
}
