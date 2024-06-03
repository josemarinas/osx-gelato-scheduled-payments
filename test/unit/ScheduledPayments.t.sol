// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {IDAO} from "@aragon/osx-commons/dao/IDAO.sol";
import {ProxyFactory} from "@aragon/osx-commons/utils/deployment/ProxyFactory.sol";
import {Automate} from "@gelato/automate/Automate.sol";
import {LibDataTypes} from "@gelato/automate/libraries/LibDataTypes.sol";
import {ScheduledPayments} from "../../src/ScheduledPayments.sol";
import {ScheduledPaymentsSetup} from "../../src/ScheduledPaymentsSetup.sol";
import {createTestDAO} from "../mocks/MockDAO.sol";
import {MockAutomate} from "../mocks/MockAutomate.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockGelato} from "../mocks/MockGelato.sol";
import {GelatoSetup} from "../base/gelato.sol";

contract ScheduledPaymentsPluginTest is Test {
    // string private _sepoliaRpcUrl = vm.envString("SEPOLIA_RPC_URL");
    // address private _gelatoAutomateAddress =
    //     address(0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0);
    // address private _gelatoAddress =
    //     address(0xCf8EDB3333Fae73b23f689229F4De6Ac95d1f707);

    GelatoSetup private _gelatoSetup;
    ScheduledPayments private _scheduledPayments;
    DAO private _dao;
    MockERC20 private _mockERC20;

    function setUp() public {
        _gelatoSetup = new GelatoSetup();
        _gelatoSetup.setupGelatoContracts();
        _dao = createTestDAO(address(this));
        bytes memory scheduledPaymentsData = abi.encodeWithSelector(
            ScheduledPayments.initialize.selector,
            IDAO(address(_dao)),
            payable(address(_gelatoSetup.automate()))
        );
        ProxyFactory _proxyFactory = new ProxyFactory(
            address(new ScheduledPayments())
        );
        address _proxyAddress = _proxyFactory.deployUUPSProxy(
            scheduledPaymentsData
        );
        _scheduledPayments = ScheduledPayments(payable(address(_proxyAddress)));
        _mockERC20 = new MockERC20("Test", "TEST");
        _mockERC20.mint(address(_dao), 100 ether);
        vm.prank(address(_dao));
        _mockERC20.approve(address(_scheduledPayments), 1 ether);
        _dao.grant(
            address(_scheduledPayments),
            address(this),
            _scheduledPayments.CREATE_AGREEMENT_PERMISSION()
        );
        _dao.grant(
            address(_scheduledPayments),
            address(this),
            _scheduledPayments.PAUSE_AGREEMENT_PERMISSION()
        );
        _dao.grant(
            address(_scheduledPayments),
            address(this),
            _scheduledPayments.EXECUTE_PAYMENT_PERMISSION()
        );
    }

    function test_initialize() public {
        address _automateAddress = address(_gelatoSetup.automate());
        vm.expectRevert(
            "Initializable: contract is already initialized"
        );
        _scheduledPayments.initialize(
            IDAO(address(_dao)),
            payable(_automateAddress)
        );
    }

    function testFuzz_CreateAgreeement(
        address token,
        address receiver,
        uint256 amount,
        uint256 startBlockNumber,
        uint64 interval,
        uint64 numberOfPayments,
        bool paused
    ) public {
        vm.assume(startBlockNumber >= block.number);
        vm.assume(numberOfPayments > 0);
        vm.assume(interval > 0);
        vm.assume(amount > 0);
        vm.assume(receiver != address(0));
        vm.assume(token != address(0));
        _scheduledPayments.createAgreement(
            receiver,
            token,
            amount,
            startBlockNumber,
            interval,
            numberOfPayments,
            paused
        );
    }

    function testFuzz_CreateAgreementInvalidStartBlockNumber(
        address token,
        address receiver,
        uint256 amount,
        uint256 startBlockNumber,
        uint64 interval,
        uint64 numberOfPayments,
        bool paused
    ) public {
        vm.assume(startBlockNumber < block.number);
        vm.assume(numberOfPayments > 0);
        vm.assume(interval > 0);
        vm.assume(amount > 0);
        vm.assume(receiver != address(0));
        vm.assume(token != address(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.InvalidStartBlockNumber.selector,
                startBlockNumber,
                block.number
            )
        );
        _scheduledPayments.createAgreement(
            receiver,
            token,
            amount,
            startBlockNumber,
            interval,
            numberOfPayments,
            paused
        );
    }

    function test_ExecutePayment() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(2 * interval);
        _scheduledPayments.executePayment(agreementId);
        vm.assertEq(
            _scheduledPayments.getAgreement(agreementId).paymentsMade,
            1
        );
        vm.assertEq(_mockERC20.balanceOf(address(1)), 1 ether);
    }

    function test_ExecutePaymentAgreementPaused() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            true
        );
        vm.roll(2 * interval);
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.AgreementPaused.selector,
                agreementId
            )
        );
        _scheduledPayments.executePayment(agreementId);
    }

    function test_ExecutePaymentAgreementNotStarted() public {
        uint64 interval = 30;
        uint64 startBlockNumber = 10;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            startBlockNumber,
            interval,
            1,
            false
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.AgreementNotStarted.selector,
                agreementId,
                startBlockNumber,
                block.number
            )
        );
        _scheduledPayments.executePayment(agreementId);
    }

    function test_ExecutePaymentPaymentIntervalNotReached() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(interval / 2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.PaymentIntervalNotReached.selector,
                agreementId,
                block.number,
                _scheduledPayments
                    .getAgreement(agreementId)
                    .lastPaymentBlockNumber + interval
            )
        );
        _scheduledPayments.executePayment(agreementId);
    }

    function test_ExecutePaymentAllPaymentsMade() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(interval + 1);
        _scheduledPayments.executePayment(agreementId);
        vm.roll(2 * interval + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.AllPaymentsMade.selector,
                agreementId,
                _scheduledPayments.getAgreement(agreementId).numberOfPayments,
                _scheduledPayments.getAgreement(agreementId).paymentsMade
            )
        );
        _scheduledPayments.executePayment(agreementId);
    }

    function test_PauseAgreement() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        _scheduledPayments.pauseAgreement(agreementId);
        vm.assertEq(_scheduledPayments.getAgreement(agreementId).paused, true);
    }

    function test_PauseAgreementAgreementPaused() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            true
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.AgreementPaused.selector,
                agreementId
            )
        );
        _scheduledPayments.pauseAgreement(agreementId);
    }

    function test_ResumeAgreement() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            true
        );
        _scheduledPayments.resumeAgreement(agreementId);
        vm.assertEq(_scheduledPayments.getAgreement(agreementId).paused, false);
    }

    function test_ResumeAgreementAgreementNotPaused() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.AgreementNotPaused.selector,
                agreementId
            )
        );
        _scheduledPayments.resumeAgreement(agreementId);
    }

    function test_ResumeAgreementAllPaymentsMade() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(interval + 1);
        _scheduledPayments.executePayment(agreementId);
        _scheduledPayments.pauseAgreement(agreementId);
        vm.expectRevert(
            abi.encodeWithSelector(
                ScheduledPayments.AllPaymentsMade.selector,
                agreementId,
                _scheduledPayments.getAgreement(agreementId).numberOfPayments,
                _scheduledPayments.getAgreement(agreementId).paymentsMade
            )
        );
        _scheduledPayments.resumeAgreement(agreementId);
    }

    function test_CheckerExecutePayment() public {
        uint64 interval = 30;
        _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(interval + 1);
        (bool canExec, bytes memory execPayload) = _scheduledPayments.checker();
        vm.assertEq(canExec, true);
        vm.assertEq(
            abi.decode(execPayload, (bytes4)),
            _scheduledPayments.executePayment.selector
        );
    }

    function test_CheckerPauseAgreement() public {
        uint64 interval = 30;
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(interval + 1);
        _scheduledPayments.executePayment(agreementId);
        (bool canExec, bytes memory execPayload) = _scheduledPayments.checker();
        vm.assertEq(canExec, true);
        vm.assertEq(
            abi.decode(execPayload, (bytes4)),
            _scheduledPayments.pauseAgreement.selector
        );
    }

    function test_CheckerMultipleAgreements() public {
        uint64 interval = 30;
        _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval * 2,
            1,
            false
        );
        uint256 agreementId = _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            1,
            false
        );
        vm.roll(interval + 1);
        (bool canExec, bytes memory execPayload) = _scheduledPayments.checker();
        vm.assertEq(canExec, true);

        vm.assertEq(
            abi.encodeWithSelector(
                _scheduledPayments.executePayment.selector,
                agreementId
            ),
            execPayload
        );
    }

    function test_CheckerNoTasks() public {
        uint64 interval = 30;
        _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            10,
            true
        );
        _scheduledPayments.createAgreement(
            address(1),
            address(_mockERC20),
            1 ether,
            block.number,
            interval,
            10,
            true
        );
        (bool canExec, bytes memory execPayload) = _scheduledPayments.checker();
        vm.assertEq(canExec, false);
        vm.assertEq(execPayload, abi.encodePacked("no transfers pending"));
    }
}
