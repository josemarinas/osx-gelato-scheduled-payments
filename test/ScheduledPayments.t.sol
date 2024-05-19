// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ScheduledPayments} from "../src/ScheduledPayments.sol";
import {DaoFactory} from "@aragon/osx/framework/dao/DaoFactory.sol";

contract ScheduledPaymentsPluginTest is Test {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    address myAddress = address(bytes20(0xf5015DcB05e13cBBeB974cF868fEda4A9C0C4648));
    address DAO_FACTORY_ADDRESS = address(bytes20(0xf96e6FD76BD0A15580604e1Ea5818D448b1041C0));

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        
    }

    function createMultisigDAO() public {
        DAOFactory daoFactory = DAOFactory(DAO_FACTORY_ADDRESS);
    }
    function testCreateAgreement() public view {
        console.log("myAddress: ", myAddress);
        console.log("myAddress: ", myAddress.balance);
        assertNotEq(myAddress.balance, 0);
        // RecurringPayment recurringPayment = new RecurringPayment();
        // recurringPayment.createAgreement(address(this), 100, address(0), 0, 0, 0);
    }
}
