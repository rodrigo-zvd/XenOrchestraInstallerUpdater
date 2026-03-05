# Xen Orchestra Installer / Updater (Custom Fork)

This is a personal fork of the original [XenOrchestraInstallerUpdater](https://github.com/ronivay/XenOrchestraInstallerUpdater) project. It includes additional features for UI customization and automatic cleanup of trial banners for the community version.

## Fork Features

This fork adds specific flags to `xo-install.cfg` (derived from `sample.xo-install.cfg`) to automate tasks that are usually manual or require specific configuration files.

For general script configuration and all original variables, please refer to the [Original Project Wiki](https://github.com/ronivay/XenOrchestraInstallerUpdater/wiki).

### 1. Banner & Warning Removal
Automates the process of removing trial banners and commercial warnings from the **Xen Orchestra "From the sources" (Community)** version.

*   **Variable**: `REMOVE_BANNER`
*   **Options**: `true` / `false`
*   **Default**: `true` (uncomment it in your `.cfg`)
*   **How it works**: After installation or update, it triggers a custom script `xo-remove-banner.sh` that modifies the source code before the final compilation.

### 2. Defaulting to XO v5 Interface
Starting with recent versions, Xen Orchestra defaults to the new v6 UI. This fork allows you to easily stick with the classic v5 interface as your primary entry point.

*   **Variable**: `XO5_UI`
*   **Options**: `true` / `false`
*   **Default**: `false`
*   **Documentation Reference**: [Using XO 5 as the Default Interface](https://github.com/vatesfr/xen-orchestra/blob/master/docs/docs/configuration.md#using-xo-5-as-the-default-interface)
*   **How it works**: When set to `true`, the installer generates a `config.mounts.toml` matching the official documentation. This ensures:
    *   Accessing `/` loads **XO 5**.
    *   Accessing `/v5` loads **XO 5**.
    *   Accessing `/v6` loads **XO 6**.

## Default Credentials

Following the original Xen Orchestra default configuration:

*   **UI Login**: `admin@admin.net`
*   **UI Password**: `admin`

## VM Import Limitation

The `xo-vm-import.sh` script downloads an experimental image directly from the **Ronivay repository** (`IMAGE_URL` is static). This image **does not** include this fork's custom features by default.

To apply this fork's enhancements to an imported VM:
1.  Access the VM via SSH.
2.  Clone **this fork's repository** inside the VM:
    `git clone https://github.com/rodrigo-zvd/XenOrchestraInstallerUpdater.git`
3.  Copy your `xo-install.cfg` with the custom variables (`REMOVE_BANNER="true"`, `XO5_UI="true"`) enabled.
4.  Run `sudo ./xo-install.sh --update`.

*Note: If using the prebuilt VM image, SSH access is usually `xo` / `xopass`. Check the original project documentation for more details.*

## Usage

1.  Copy `sample.xo-install.cfg` to `xo-install.cfg`.
2.  Uncomment and set your preferred fork features at the bottom of the file.
3.  Run the installation script as usual:
    ```bash
    sudo ./xo-install.sh
    ```

## Credits
All the core installation and dependency logic belongs to the [original project](https://github.com/ronivay/XenOrchestraInstallerUpdater). This fork only adds convenience features for home users and enthusiasts.
