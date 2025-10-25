// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMEVResponse} from "./IMEVResponse.sol";

contract MEVResponse is IMEVResponse {

    event MEVAlertRecorded(
        address indexed mevBot,
        address indexed victim,
        address indexed token,
        uint256 frontrunAmount,
        uint256 victimAmount,
        uint256 backrunAmount,
        uint256 extractedValue,
        uint256 blockNumber,
        uint256 timestamp
    );

    enum SeverityLevel { LOW, MEDIUM, HIGH, CRITICAL }

    struct MEVAlert {
        address mevBot;
        address victim;
        address token;
        uint256 frontrunAmount;
        uint256 victimAmount;
        uint256 backrunAmount;
        uint256 extractedValue;
        uint256 blockNumber;
        uint256 timestamp;
        SeverityLevel severity;
    }

    MEVAlert[] public alerts;
    mapping(address => uint256) public alertCountByBot;
    mapping(address => uint256) public alertCountByVictim;
    mapping(address => bool) public blacklistedBots;
    mapping(address => uint256) public totalExtractedByBot;

    uint256 public totalMEVExtracted;
    uint256 public criticalAlertCount;

    address public immutable TRAP_CONFIG;

    constructor(address _trapConfig) {
        require(_trapConfig != address(0), "Invalid trap config");
        TRAP_CONFIG = _trapConfig;
    }

    modifier onlyTrapConfig() {
        require(msg.sender == TRAP_CONFIG, "Only trap config");
        _;
    }

    function recordMEVAlert(
        address mevBot,
        address victim,
        address token,
        uint256 frontrunAmount,
        uint256 victimAmount,
        uint256 backrunAmount,
        uint256 blockNumber,
        uint256 extractedValue
    ) external onlyTrapConfig {
        SeverityLevel severity = calculateSeverity(extractedValue);

        if (severity == SeverityLevel.CRITICAL) {
            blacklistedBots[mevBot] = true;
            criticalAlertCount++;
        }

        alerts.push(MEVAlert({
            mevBot: mevBot,
            victim: victim,
            token: token,
            frontrunAmount: frontrunAmount,
            victimAmount: victimAmount,
            backrunAmount: backrunAmount,
            extractedValue: extractedValue,
            blockNumber: blockNumber,
            timestamp: block.timestamp,
            severity: severity
        }));

        alertCountByBot[mevBot]++;
        alertCountByVictim[victim]++;
        totalExtractedByBot[mevBot] += extractedValue;
        totalMEVExtracted += extractedValue;

        emit MEVAlertRecorded(
            mevBot,
            victim,
            token,
            frontrunAmount,
            victimAmount,
            backrunAmount,
            extractedValue,
            blockNumber,
            block.timestamp
        );
    }

    function calculateSeverity(uint256 extractedValue) internal pure returns (SeverityLevel) {
        if (extractedValue < 1 ether) return SeverityLevel.LOW;
        else if (extractedValue < 5 ether) return SeverityLevel.MEDIUM;
        else if (extractedValue < 20 ether) return SeverityLevel.HIGH;
        else return SeverityLevel.CRITICAL;
    }

    function getAlertCount() external view returns (uint256) {
        return alerts.length;
    }

    function getAlert(uint256 index) external view returns (MEVAlert memory) {
        require(index < alerts.length, "Index out of bounds");
        return alerts[index];
    }

    function getLatestAlerts(uint256 count) external view returns (MEVAlert[] memory) {
        uint256 length = alerts.length;
        uint256 returnCount = count > length ? length : count;
        MEVAlert[] memory latestAlerts = new MEVAlert[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            latestAlerts[i] = alerts[length - returnCount + i];
        }
        return latestAlerts;
    }

    function getCriticalAlerts() external view returns (MEVAlert[] memory) {
        uint256 criticalCount = 0;
        for (uint256 i = 0; i < alerts.length; i++) {
            if (alerts[i].severity == SeverityLevel.CRITICAL) criticalCount++;
        }
        MEVAlert[] memory criticalAlerts = new MEVAlert[](criticalCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < alerts.length; i++) {
            if (alerts[i].severity == SeverityLevel.CRITICAL) {
                criticalAlerts[currentIndex] = alerts[i];
                currentIndex++;
            }
        }
        return criticalAlerts;
    }

    function isBotBlacklisted(address bot) external view returns (bool) {
        return blacklistedBots[bot];
    }

    function getStatistics() external view returns (
        uint256 totalAlerts,
        uint256 totalExtracted,
        uint256 criticalAlerts,
        uint256 blacklistedBotCount
    ) {
        totalAlerts = alerts.length;
        totalExtracted = totalMEVExtracted;
        criticalAlerts = criticalAlertCount;
        blacklistedBotCount = 0;
        for (uint256 i = 0; i < alerts.length; i++) {
            if (blacklistedBots[alerts[i].mevBot]) blacklistedBotCount++;
        }
    }

    function getBotStatistics(address bot) external view returns (
        uint256 alertCount,
        uint256 totalExtracted,
        bool isBlacklisted
    ) {
        return (
            alertCountByBot[bot],
            totalExtractedByBot[bot],
            blacklistedBots[bot]
        );
    }
}
