// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PluginUUPSUpgradeable} from "@aragon/osx-commons/plugin/PluginUUPSUpgradeable.sol";
import {IDAO} from "@aragon/osx-commons/dao/IDAO.sol";
import {Automate} from "@gelato/automate/Automate.sol";
import {LibDataTypes} from "@gelato/automate/libraries/LibDataTypes.sol";

contract ScheduledPayments is PluginUUPSUpgradeable {
    struct Agreement {
        address recipient;
        uint256 amount;
        uint256 startBlockNumber;
        address token;
        uint8 interval;
        uint8 numberOfPayments;
    }
    address private _automateAddress;
    // agreementNonce is used to generate unique agreement IDs
    uint256 private _agreementNonce;
    // agreements is a mapping of agreement IDs to agreements
    mapping(uint256 => Agreement) public agreements;

    function initialize(IDAO _dao, address _automate) public initializer {
        _automateAddress = _automate;
    }

    function createAgreement(
        address _recipient,
        address _token,
        uint256 _amount,
        uint256 _startBlockNumber,
        uint8 _interval,
        uint8 _numberOfPayments
    ) public {

        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](1);
        modules[0] = LibDataTypes.Module.PROXY;
        LibDataTypes.ModuleData memory gelatoModules = LibDataTypes.ModuleData({
            modules: modules ,
            args: new bytes[](1)
        });
        Automate automate = Automate(_automateAddress);
        // automate.createTask(
        //     address(this.dao),
        //     abi.encodeWithSignature("executePayment(uint256)", _agreementNonce),
        //     gelatoModules
        // );
    }

    function executePayment(uint256 _agreementId) public {
        Agreement storage agreement = agreements[_agreementId];
        // require(
        //     block.timestamp >= agreement.lastPayment + agreement.interval,
        //     "ScheduledPaymentsPlugin: Payment not due"
        // );
        // agreement.lastPayment = block.timestamp;
        // payable(agreement.recipient).transfer(agreement.amount);
    }
}
