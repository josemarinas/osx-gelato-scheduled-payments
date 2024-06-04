// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {ScheduledPaymentsSetup} from "../src/ScheduledPaymentsSetup.sol";

contract DeployScript is Script {
    address _pluginRepoFactoryAddress = 0x07f49c49Ce2A99CF7C28F66673d406386BDD8Ff4;
    string _subdomain = "schedule-payments-plugin-test-3";
    bytes _buildMetadata = "ipfs://QmeTQS7ozDeLXBEddPM9bwXz5ToENEseAjmHCb9fwxEpgS";
    bytes _releaseMetadata = "ipfs://QmZFyrpVFpHakhFuFCWpTK9xCM1ojAaNQcFTxPjtNykyNy";
    address _maintainer = 0x51798F574f728de2Eb706dFE154f62b36446dbe1;
    address _automateAddress = 0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ScheduledPaymentsSetup setup = new ScheduledPaymentsSetup();

        PluginRepoFactory pluginRepoFactory = PluginRepoFactory(_pluginRepoFactoryAddress);
        pluginRepoFactory.createPluginRepoWithFirstVersion(
            _subdomain,
            address(setup),
            _maintainer,
            _releaseMetadata,
            _buildMetadata
        );

        vm.stopBroadcast();
    }
}
