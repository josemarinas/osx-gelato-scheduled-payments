// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import {IAutomate} from "@gelato/automate/interfaces/IAutomate.sol";
import {Gelatofied} from "@gelato/automate/vendor/gelato/Gelatofied.sol";
import {LibDataTypes} from "@gelato/automate/libraries/LibDataTypes.sol";

contract MockAutomate is Gelatofied, IAutomate {

    mapping(LibDataTypes.Module => address) public taskModuleAddresses;
    constructor(address payable _gelato) Gelatofied(_gelato) {}

    function createTask(
        address execAddress,
        bytes calldata execData,
        LibDataTypes.ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId) {
        return bytes32(0);
    }

    function cancelTask(bytes32 taskId) external {}

    function exec(
        address taskCreator,
        address execAddress,
        bytes memory execData,
        LibDataTypes.ModuleData calldata moduleData,
        uint256 txFee,
        address feeToken,
        bool revertOnFailure
    ) external {}

    function exec1Balance(
        address taskCreator,
        address execAddress,
        bytes memory execData,
        LibDataTypes.ModuleData calldata moduleData,
        Gelato1BalanceParam calldata oneBalanceParam,
        bool revertOnFailure
    ) external {}

    function setModule(
        LibDataTypes.Module[] calldata modules,
        address[] calldata moduleAddresses
    ) external {
        for (uint256 i = 0; i < modules.length; i++) {
            taskModuleAddresses[modules[i]] = moduleAddresses[i];
        }
    }

    function getFeeDetails() external view returns (uint256, address) {
        return (0, address(0));
    }

    function getTaskIdsByUser(
        address taskCreator
    ) external view returns (bytes32[] memory) {
        return new bytes32[](0);
    }

    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) external pure returns (bytes32 taskId) {
        return bytes32(0);
    }
}
