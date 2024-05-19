// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ScheduledPayments} from "../src/ScheduledPayments.sol";

contract ScheduledPaymentsPluginTest is Test {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    address myAddress = address(bytes20(0xf5015DcB05e13cBBeB974cF868fEda4A9C0C4648));
    
    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
    }
    function testCreateAgreement() public view {
        console2.log("myAddress: ", myAddress);
        console2.log("myAddress: ", myAddress.balance);
        assertNotEq(myAddress.balance, 0);
        // RecurringPayment recurringPayment = new RecurringPayment();
        // recurringPayment.createAgreement(address(this), 100, address(0), 0, 0, 0);
    }
}
