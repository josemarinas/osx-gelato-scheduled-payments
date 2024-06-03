// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import {IGelato} from "@gelato/automate/integrations/Types.sol";

contract MockGelato is IGelato {
    function feeCollector() external view returns (address) {
        return address(0);
    }
}