pragma solidity ^0.8.8;

import {IOpsProxyFactory} from "@gelato/automate/integrations/Types.sol";
import {console} from "forge-std/Test.sol";


contract MockOpsProxyFactory is IOpsProxyFactory {
    address private _opsProxy;
    
    function getProxyOf(address account) external view returns (address, bool){
        console.log("MockOpsProxyFactory.getProxyOf: account: %s", account);
        return (address(1), true);
    }
    constructor(address opsProxy) {
        _opsProxy = opsProxy;
     }
}
