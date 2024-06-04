pragma solidity ^0.8.8;

import {ScheduledPayments} from "./ScheduledPayments.sol";
import {Automate} from "@gelato/automate/Automate.sol";
import {IDAO} from "@aragon/osx-commons/dao/IDAO.sol";
import {PluginUpgradeableSetup} from "@aragon/osx-commons/plugin/setup/PluginUpgradeableSetup.sol";
import {ProxyLib} from "@aragon/osx-commons/utils/deployment/ProxyLib.sol";
import {PermissionLib} from "@aragon/osx-commons/permission/PermissionLib.sol";

contract ScheduledPaymentsSetup is PluginUpgradeableSetup {
    using ProxyLib for address;

    /// @notice The contract constructor, that deploys the `SchedulePayments` plugin logic contract.
    constructor() PluginUpgradeableSetup(address(new ScheduledPayments())) {}

    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        // Decode `_data` to extract the params needed for deploying and initializing `SchedulePayments` plugin.
        address payable automate = abi.decode(_data, (address));

        // Deploy and initialize the plugin UUPS proxy.
        plugin = IMPLEMENTATION.deployUUPSProxy(
            abi.encodeCall(ScheduledPayments.initialize, (IDAO(_dao), automate))
        );

        address gelato = Automate(automate).gelato();

        // // Prepare permissions
        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](5);

        // Grant `CREATE_AGREEMENT_PERMISSION`
        // to the DAO to allow the DAO to create agreements.
        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .CREATE_AGREEMENT_PERMISSION()
        });
        // Grant `PAUSE_AGREEMENT_PERMISSION` and `RESUME_AGREEMENT_PERMISSION`
        // to the DAO to allow the DAO to pause and resume agreements.
        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .PAUSE_AGREEMENT_PERMISSION()
        });
        permissions[2] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .RESUME_AGREEMENT_PERMISSION()
        });
        // Grant `EXECUTE_PAYMENT_PERMISSION` to the automate address
        // to allow the automate address to execute payments.
        permissions[3] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: gelato,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .EXECUTE_PAYMENT_PERMISSION()
        });
        // Grant `PAUSE_AGREEMENT_PERMISSION` to the automate address
        permissions[4] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: gelato,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .PAUSE_AGREEMENT_PERMISSION()
        });

        preparedSetupData.helpers = new address[](1);
        preparedSetupData.helpers[0] = gelato;
        preparedSetupData.permissions = permissions;
    }

    function prepareUpdate(
        address _dao,
        uint16 _fromBuild,
        SetupPayload calldata _payload
    )
        external
        view
        override
        returns (
            bytes memory initData,
            PreparedSetupData memory preparedSetupData
        )
    {
        (initData);
    }

    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        view
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        address gelato = _payload.currentHelpers[0];
        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](5);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .CREATE_AGREEMENT_PERMISSION()
        });
        // Revoke `PAUSE_AGREEMENT_PERMISSION` and `RESUME_AGREEMENT_PERMISSION`
        // to the DAO to allow the DAO to pause and resume agreements.
        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .PAUSE_AGREEMENT_PERMISSION()
        });
        permissions[2] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .RESUME_AGREEMENT_PERMISSION()
        });
        // Revoke `EXECUTE_PAYMENT_PERMISSION` to the automate address
        // to allow the automate address to execute payments.
        permissions[3] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: gelato,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .EXECUTE_PAYMENT_PERMISSION()
        });
        // Revoke `PAUSE_AGREEMENT_PERMISSION` to the automate address
        permissions[4] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: gelato,
            condition: PermissionLib.NO_CONDITION,
            permissionId: ScheduledPayments(IMPLEMENTATION)
                .PAUSE_AGREEMENT_PERMISSION()
        });
    }
}
