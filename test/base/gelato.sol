pragma solidity ^0.8.17;
import {Test} from "forge-std/Test.sol";

import {MockGelato} from "../mocks/MockGelato.sol";
import {Automate} from "@gelato/automate/Automate.sol";
import {MockAutomate} from "../mocks/MockAutomate.sol";
import {MockOpsProxyFactory} from "../mocks/MockOpsProxyFactory.sol";
import {MockProxyModule} from "../mocks/MockProxyModule.sol";
import {ProxyModule} from "@gelato/automate/taskModules/ProxyModule.sol";
import {TriggerModule} from "@gelato/automate/taskModules/TriggerModule.sol";
import {SingleExecModule} from "@gelato/automate/taskModules/SingleExecModule.sol";
import {LibDataTypes} from "@gelato/automate/libraries/LibDataTypes.sol";
import {OpsProxyFactory} from "@gelato/automate/opsProxy/OpsProxyFactory.sol";
import {OpsProxy} from "@gelato/automate/opsProxy/OpsProxy.sol";


contract GelatoSetup is Test {
    MockGelato public gelato;
    MockAutomate public automate;
    MockOpsProxyFactory public proxyFactory;
    OpsProxy public opsProxy;
    MockProxyModule public proxyModule;
    TriggerModule public triggerModule;
    SingleExecModule public singleExecModule;

    function setupGelatoContracts() external {
        gelato = new MockGelato();
        automate = new MockAutomate(payable(address(gelato)));
        opsProxy = new OpsProxy(address(automate));
        proxyFactory = new MockOpsProxyFactory(address(opsProxy));
        proxyModule = new MockProxyModule(proxyFactory);
        triggerModule = new TriggerModule();
        singleExecModule = new SingleExecModule();
        address[] memory t = new address[](3);
        LibDataTypes.Module[] memory m = new LibDataTypes.Module[](3);
        t[0] = address(proxyModule);
        m[0] = LibDataTypes.Module.PROXY;
        t[1] = address(triggerModule);
        m[1] = LibDataTypes.Module.TRIGGER;
        t[2] = address(singleExecModule);
        m[2] = LibDataTypes.Module.SINGLE_EXEC;
        automate.setModule(m,t);
    }
}