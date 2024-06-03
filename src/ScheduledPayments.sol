// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {console} from "forge-std/Test.sol";

import {PluginUUPSUpgradeable} from "@aragon/osx-commons/plugin/PluginUUPSUpgradeable.sol";
import {IDAO} from "@aragon/osx-commons/dao/IDAO.sol";
import {Automate} from "@gelato/automate/Automate.sol";
import {LibDataTypes} from "@gelato/automate/libraries/LibDataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ScheduledPayments is PluginUUPSUpgradeable {
    struct Agreement {
        address recipient;
        uint256 amount;
        uint256 startBlockNumber;
        uint256 lastPaymentBlockNumber;
        address token;
        uint64 interval;
        uint64 numberOfPayments;
        uint64 paymentsMade;
        bool paused;
    }
    bytes32 public constant PAUSE_AGREEMENT_PERMISSION =
        keccak256("PAUSE_AGREEMENT_PERMISSION");
    bytes32 public constant RESUME_AGREEMENT_PERMISSION =
        keccak256("RESUME_AGREEMENT_PERMISSION");
    bytes32 public constant CREATE_AGREEMENT_PERMISSION =
        keccak256("CREATE_AGREEMENT_PERMISSION");
    bytes32 public constant EXECUTE_PAYMENT_PERMISSION =
        keccak256("EXECUTE_PAYMENT_PERMISSION");

    address private _automateAddress;
    // agreementNonce is used to generate unique agreement IDs
    uint256 private _agreementNonce;
    // agreements is a mapping of agreement IDs to agreements
    mapping(uint256 => Agreement) private _agreements;
    error InvalidStartBlockNumber(
        uint256 startBlockNumber,
        uint256 currentBlockNumber
    );
    error InvalidNumberOfPayments(uint64 numberOfPayments);
    error AgreementPaused(uint256 agreementId);
    error AgreementNotPaused(uint256 agreementId);
    error AgreementNotStarted(
        uint256 agreementId,
        uint256 startBlockNumber,
        uint256 currentBlockNumber
    );
    error PaymentIntervalNotReached(
        uint256 agreementId,
        uint256 currentBlockNumber,
        uint256 nextPaymentBlockNumber
    );
    error AllPaymentsMade(
        uint256 agreementId,
        uint64 numberOfPayments,
        uint64 paymentsMade
    );
    error InvalidAmount(uint256 amount);

    error InvalidRecipient(address recipient);

    error InvalidToken(address token);

    error InvalidInterval(uint64 interval);

    function initialize(
        IDAO _dao,
        address payable _automate
    ) public initializer {
        __PluginUUPSUpgradeable_init(_dao);
        _automateAddress = _automate;
        _createCheckerTask();
    }

    function createAgreement(
        address _recipient,
        address _token,
        uint256 _amount,
        uint256 _startBlockNumber,
        uint64 _interval,
        uint64 _numberOfPayments,
        bool _paused
    ) external auth(CREATE_AGREEMENT_PERMISSION) returns (uint256) {
        if (_amount == 0) {
            revert InvalidAmount(_amount);
        }
        if (_recipient == address(0)) {
            revert InvalidRecipient(_recipient);
        }
        // TODO check if token is ERC20, ERC721, or ERC1155 and add support
        // for ETH
        if (_token == address(0)) {
            revert InvalidToken(_token);
        }
        if (_interval == 0) {
            revert InvalidInterval(_interval);
        }
        // check that the start block number is less than the current block number
        if (_startBlockNumber < block.number) {
            revert InvalidStartBlockNumber(_startBlockNumber, block.number);
        }
        if (_numberOfPayments == 0) {
            revert InvalidNumberOfPayments(_numberOfPayments);
        }
        // create agreement
        uint256 agreementId = _agreementNonce;
        _agreements[agreementId] = Agreement({
            recipient: _recipient,
            token: _token,
            amount: _amount,
            startBlockNumber: _startBlockNumber,
            interval: _interval,
            numberOfPayments: _numberOfPayments,
            paymentsMade: 0,
            paused: _paused,
            lastPaymentBlockNumber: 0
        });
        _agreementNonce++;
        return agreementId;
    }

    function executePayment(
        uint256 _agreementId
    ) external auth(EXECUTE_PAYMENT_PERMISSION) {
        _checkAgreementPayable(_agreementId);
        Agreement storage agreement = _agreements[_agreementId];
        // increment the number of payments made
        agreement.paymentsMade++;
        // update the last payment block number
        agreement.lastPaymentBlockNumber = block.number;
        // transfer the payment
        _transfer(agreement.token, agreement.recipient, agreement.amount);
    }

    function pauseAgreement(
        uint256 _agreementId
    ) external auth(PAUSE_AGREEMENT_PERMISSION) {
        Agreement storage agreement = _agreements[_agreementId];
        // check that the agreement is not paused
        if (agreement.paused) {
            revert AgreementPaused(_agreementId);
        }
        agreement.paused = true;
    }

    function resumeAgreement(
        uint256 _agreementId
    ) external auth(PAUSE_AGREEMENT_PERMISSION) {
        Agreement storage agreement = _agreements[_agreementId];
        // check that the agreement is paused
        if (!agreement.paused) {
            revert AgreementNotPaused(_agreementId);
        }
        if (agreement.paymentsMade >= agreement.numberOfPayments) {
            revert AllPaymentsMade(
                _agreementId,
                agreement.numberOfPayments,
                agreement.paymentsMade
            );
        }
        agreement.paused = false;
    }

    function getAgreement(
        uint256 agreementId
    ) external view returns (Agreement memory) {
        return _agreements[agreementId];
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        for (uint256 i = 0; i < _agreementNonce; i++) {
            Agreement storage agreement = _agreements[i];
            // automatically cancel agreement if all payments have been made
            if (agreement.paymentsMade >= agreement.numberOfPayments) {
                execPayload = abi.encodeWithSelector(
                    this.pauseAgreement.selector,
                    i
                );
                return (true, execPayload);
            }
            // check if the agreement is payable
            if (
                agreement.startBlockNumber > block.number ||
                agreement.lastPaymentBlockNumber + agreement.interval >
                block.number ||
                agreement.paused
            ) {
                continue;
            }
            // if the agreement is payable, return the payload to execute the payment
            execPayload = abi.encodeWithSelector(
                this.executePayment.selector,
                i
            );
            console.log("execPayload");
            return (true, execPayload);
        }
        return (false, bytes("no transfers pending"));
    }

    function _createCheckerTask() internal returns (bytes32) {
        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](3);
        bytes[] memory args = new bytes[](3);
        modules[0] = LibDataTypes.Module.RESOLVER;
        modules[1] = LibDataTypes.Module.PROXY;
        modules[2] = LibDataTypes.Module.RESOLVER;
        // Checker module args
        // address(this) is the contract address and this.checker.selector
        // is the checker function selector
        args[0] = abi.encode(address(this), this.checker.selector);
        // Proxy module args must be empty
        args[1] = bytes("");
        // Trigger module args each block
        args[2] = abi.encode(
            LibDataTypes.TriggerType.BLOCK,
            abi.encode(bytes(""))
        );
        return
            Automate(_automateAddress).createTask(
                address(this),
                abi.encodeWithSelector(this.executePayment.selector),
                LibDataTypes.ModuleData(modules, args),
                address(0)
            );
    }

    function _checkAgreementPayable(uint256 agreementId) internal view {
        Agreement storage agreement = _agreements[agreementId];
        if (agreement.paused) {
            revert AgreementPaused(agreementId);
        }
        if (agreement.startBlockNumber > block.number) {
            revert AgreementNotStarted(
                agreementId,
                agreement.startBlockNumber,
                block.number
            );
        }
        if (
            agreement.lastPaymentBlockNumber + agreement.interval > block.number
        ) {
            revert PaymentIntervalNotReached(
                agreementId,
                block.number,
                agreement.lastPaymentBlockNumber + agreement.interval
            );
        }
        if (agreement.paymentsMade >= agreement.numberOfPayments) {
            revert AllPaymentsMade(
                agreementId,
                agreement.numberOfPayments,
                agreement.paymentsMade
            );
        }
    }

    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool ok) {
        // TODO implement ETH transfer logic
        // TODO ERC721 transfer logic
        // TODO ERC1155 transfer logic
        return IERC20(_token).transferFrom(address(dao()), _to, _amount);
    }

    uint256[47] private __gap;
}
