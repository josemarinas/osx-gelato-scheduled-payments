pragma solidity ^0.8.8;

import {IProxyModule, IOpsProxyFactory} from "@gelato/automate/integrations/Types.sol";

contract MockProxyModule is IProxyModule {
    address public opsProxyFactory;

    constructor(IOpsProxyFactory proxyFactory) {
        opsProxyFactory = address(proxyFactory);
    }
}
