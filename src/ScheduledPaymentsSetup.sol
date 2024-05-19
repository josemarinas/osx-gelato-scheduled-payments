pragma solidity ^0.8.8;

import {IDAO} from "@aragon/osx-commons/dao/IDAO.sol";
import {PermissionLib} from "@aragon/osx-commons/permission/PermissionLib.sol";
import {PluginSetup} from "@aragon/osx-commons/plugin/setup/PluginSetup.sol";
import {IPluginSetup} from "@aragon/osx-commons/plugin/setup/IPluginSetup.sol";
import {ProxyLib} from "@aragon/osx-commons/utils/deployment/ProxyLib.sol";
import {ScheduledPayments} from "./ScheduledPayments.sol";

abstract contract ScheduledPaymentsSetup is PluginSetup {
    ScheduledPayments private immutable _scheduledPaymentsBase;

    constructor() {
        _scheduledPaymentsBase = new ScheduledPayments();
    }
    // @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        // no need to decode `_data` as it is not used in this plugin

        // Prepare and Deploy the plugin proxy.
        plugin = ProxyLib.deployUUPSProxy(
            address(_scheduledPaymentsBase),
            abi.encode(
                _scheduledPaymentsBase.initialize.selector,
                IDAO(_dao),
                // Automate address
                address(0)
            )
        );

        // // Prepare permissions
        // PermissionLib.MultiTargetPermission[]
        //     memory permissions = new PermissionLib.MultiTargetPermission[](1);

        // // Set permissions to be granted.
        // // Grant the list of permissions of the plugin to the DAO.
        // permissions[0] = PermissionLib.MultiTargetPermission({
        //     operation: PermissionLib.Operation.Grant,
        //     where: plugin,
        //     who: _dao,
        //     condition: PermissionLib.NO_CONDITION,
        //     permissionId: _scheduledPaymentsBase.CANCEL_AGREEMENT_PERMISSION_ID()
        // });

        // preparedSetupData.permissions = permissions;

    }

    // @inheritdoc IPluginSetup
    // function prepareUpdate(
    //     address _dao,
    //     uint16 _currentBuild,
    //     SetupPayload calldata _payload
    // )
    //     external
    //     pure
    //     override
    //     returns (bytes memory initData, PreparedSetupData memory preparedSetupData)
    // {

    // }

    // @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    ) external view returns (PermissionLib.MultiTargetPermission[] memory permissions) {
        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](1);

        // Set permissions to be Revoked.
        // permissions[0] = PermissionLib.MultiTargetPermission({
        //     operation: PermissionLib.Operation.Revoke,
        //     where: _payload.plugin,
        //     who: _dao,
        //     condition: PermissionLib.NO_CONDITION,
        //     permissionId: _scheduledPaymentsBase.CANCEL_AGREEMENT_PERMISSION_ID()
        // });
    }

    // // @inheritdoc IPluginSetup
    // function implementation() public override view returns (address) {
    //     return address(_scheduledPaymentsBase);
    // }
}
