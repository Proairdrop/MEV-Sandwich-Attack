// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/MEVResponse.sol";
import "../src/MEVDetectorTrap.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address placeholder = 0x0000000000000000000000000000000000000001;
        MEVResponse response = new MEVResponse(placeholder);
        console.log("MEVResponse:", address(response));

        MEVDetectorTrap trap = new MEVDetectorTrap();
        console.log("MEVDetectorTrap:", address(trap));

        (uint256 min, uint256 sig, uint256 crit) = trap.getThresholds();
        console.log("Thresholds - Min:", min, "Significant:", sig, "Critical:", crit);

        vm.stopBroadcast();
    }
}
