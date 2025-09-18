# RadicalXiaomiDebloat
No Root Required–This will get risk of everything not strictly vital; at the end, there won't be one Google or Miui Service left standing if the phone can function without them. This also requires you to replace all apps such as a Gallery, SMS, Video Player, Browser and File Manager.  

# PowerShell ADB Utility Script

The Script manages Root-Free bulk uninstallation of all the packages listed in the text file. A text file is provided with a very lengthy template list and it will try to uninstall them all, even though most are probably not installed on a given phone, but just in case for the sake of completion. The result is a phone, that is likely not well suited as a primary daily driver. It might also not have the best system stability (although I removed packages that caused instability in my testing ony Xioami Redmi Note 11 Pro). However, it sure won't get bogged down by services running in the background and, from a privacy perspective, is great.

All packages removed with this script can be reactivated by running in CMD "<adb_path_exe> shell cmd package install-existing <package_name>.

Note: Miui forbids you to install APKs per USB without a Xioami Account logged in, which is like the entire point why someone might want to do this; therefore, you should copy your APKs from your PC to your device, also via adb, with this command: "push <local_path> <device_path>". Then, use the horrible Xioami ad-infested file manager on the phone to install them. This is by far the easiest work around. Once you have real file manager installed, you can uninstall that bloat with "<adb_path_exe> shell pm uninstall --user 0 com.mi.android.globalFileexplorer>.
It is for this reason that the file manager is not part of the debloat list provided here. Though one could just add it this package to the list and the script handles the removal, should one wish to do so.


## 🌟 Features

-   **Dual Mode Operation**: Choose between **Removal Mode** or **Installation Mode** at runtime.
-   **Bulk Processing**: Reads instructions from simple text files (`uninstall_list.txt` and `install_list.txt`) to process apps in batches.
-   **Intelligent Uninstall**:
    -   Handles various input formats (package name only or full command).
    -   Features a smart fallback: if an uninstall is blocked by the OS (`Failure [-1000]`), it automatically attempts to **disable** the app instead.
    -   Uses a **conditional delay** between operations to avoid overwhelming older devices (e.g., longer pause after a success, shorter after a failure).
-   **Flexible Installation**:
    -   Installs single `.apk` files from a list.
    -   Automatically detects and **scans folders**, installing all `.apk` files found within them and their subfolders.
    -   Includes a fixed delay after each installation for device stability.
-   **User-Friendly & Portable**:
    -   Prompts for the `adb.exe` path on first run, making it adaptable to any setup.
    -   All necessary files (`.txt` lists, logs) are relative to the script's location.
    -   Includes a simple `.bat` launcher for one-click execution.

---

## ⚙️ Setup and Installation

Before you can use the script, you need to have ADB set up and your Android device correctly configured.

### ### 1. Install ADB Platform-Tools

ADB (Android Debug Bridge) is a command-line tool that lets your computer communicate with your Android device.

1.  Download the official **SDK Platform-Tools** for Windows from Google's website: [developer.android.com/studio/releases/platform-tools](https://developer.android.com/studio/releases/platform-tools)
2.  Extract the `.zip` file to a simple, memorable location on your computer, for example: `C:\platform-tools`.

### ### 2. Enable USB Debugging on Your Device

Your Android device must be in "Developer mode" to accept ADB commands.

1.  On your device, go to **Settings** > **About phone**.
2.  Tap on the **Build number** entry seven times in a row. You will see a message saying, "You are now a developer!"
3.  Go back to the main Settings menu, then go to **System** > **Developer options**.
4.  Scroll down and enable the **USB debugging** toggle.
5.  Connect your device to your computer with a USB cable. Your device will show a prompt asking you to "Allow USB debugging?". Check the box to "Always allow from this computer" and tap **Allow**.

### ### 3. Download the Script Files

1.  Download the `run_script.bat` and `uninstaller_logic.ps1` files.
2.  Place both files in a convenient folder. For simplicity, you can place them directly inside the `platform-tools` folder you created in Step 1.

---

## 🚀 How to Use

### ### Running the Script

To start, simply **double-click the `run_script.bat` file**. This will open a command window and launch the main PowerShell script with the correct permissions.

### ### Initial Setup (First Run)

The very first time you run the script, it will ask you to provide the path to your `adb.exe` file.

-   You need to provide the full, absolute path. For example, if you followed the setup guide, you would enter:
    `C:\platform-tools\adb.exe`
-   The script validates the path and will keep asking until a correct path to `adb.exe` is provided. This path is not saved and is only required for the current session.

### ### Choosing an Operation Mode

If the script detects a file named `install_list.txt` in its folder, it will ask you to choose a mode:

-   **Enter `1` for Removal Mode**: The script will read `uninstall_list.txt` and begin removing/disabling apps.
-   **Enter `2` for Installation Mode**: The script will read `install_list.txt` and begin installing `.apk` files.

If `install_list.txt` is not found, the script will automatically start in **Removal Mode**.

---

## 📄 Working with the Text Files

All operations are controlled by two simple text files you create in the same folder as the script.

### ### `uninstall_list.txt`

This file is for removing or disabling packages.

-   **Format**: One package identifier per line.
-   **Flexibility**: The script is smart. You can provide just the package name or a full command line; the script will correctly extract the package name in either case.

**Example `uninstall_list.txt`:**

```
# Just the package name (recommended)
com.google.android.apps.photos

# A full command line also works
adb shell pm uninstall --user 0 com.google.android.youtube
```

### ### `install_list.txt`

This file is for installing `.apk` files.

-   **Format**: One file path or folder path per line.
-   **Path Handling**: The script supports three types of paths:
    1.  **Absolute Path**: A full path to a single `.apk` file anywhere on your computer.
    2.  **Relative Path**: A path to an `.apk` file relative to the script's folder.
    3.  **Folder Path**: A path to a folder. The script will find and install **all** `.apk` files inside that folder and any of its subfolders.

**Example `install_list.txt`:**

```
# 1. Absolute path to a single APK
C:\Users\<user>\Downloads\apps\F-Droid.apk

# 2. You can use quotes if the path has spaces
"C:\My Android Apps\AuroraStore.apk"

# 3. Relative path (assumes 'apks' is a subfolder next to the script)
apks\SimpleKeyboard.apk

# 4. A path to a folder (will install all APKs inside)
C:\Users\<user>\Downloads\My-APKs-Collection
```

---

## 🔬 How the Script Works (A Deeper Dive)

The script contains logic to make the process as robust as possible.

### ### Removal Mode Logic

When uninstalling, the script first attempts a standard `pm uninstall` command.

-   **Fallback on Failure**: If the command fails with the specific error `Failure [-1000]` (which means the OS is blocking the removal), the script automatically executes a fallback command, `pm disable-user`, to deactivate the package for the current user.
-   **Conditional Delay**: The script pauses after each attempt to let the device recover. The delay is *conditional*: it waits longer after a successful operation (`3 seconds`) and shorter if the app was already gone (`1 second`), making it more efficient.

### ### Installation Mode Logic

When installing, the script processes each line of `install_list.txt`.

-   **Folder Scanning**: If a path points to a directory, the script performs a **recursive scan**, finding every `.apk` file in that folder and all its subfolders. It then attempts to install each one.
-   **Fixed Delay**: The script pauses for a fixed duration (`5 seconds`) after every installation attempt, whether it succeeded or failed, to ensure stability.

## ⚠️ Disclaimer

Removing system packages can be risky and may cause system instability or prevent your device from booting. Always back up your data before proceeding. You use this tool at your own risk.
