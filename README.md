Certainly! Below is the complete **README** for your **GoPro Transfer and Conversion Daemon** project. You can easily create a `README.md` file on your local machine by following the instructions provided after the content.

---

```markdown
# GoPro Transfer and Conversion Daemon

Automate the transfer and conversion of your GoPro videos with ease using this comprehensive shell and Python-based solution. Designed for efficiency and flexibility, this project ensures your GoPro footage is seamlessly downloaded, organized, and converted according to your specified configurations.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Transfer Configuration](#transfer-configuration)
  - [Conversion Configuration](#conversion-configuration)
- [Usage](#usage)
- [Script Overview](#script-overview)
  - [Shell Script](#shell-script)
  - [Python Script](#python-script)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Automated File Transfer**: Automatically download all supported video files from your GoPro to a designated local directory.
- **Flexible Conversion Options**: Customize video resolution, bitrate, codec, quality, cropping, audio removal, GPS data retention, GPX extraction, and brightness adjustments.
- **Timestamp-Based Cutting**: Trim videos based on specified start and end timestamps or set a duration.
- **Multiple Video Format Support**: Processes `.mp4`, `.mkv`, `.avi`, and `.mov` files, regardless of case variations (e.g., `.MP4`, `.MKV`).
- **Case-Insensitive File Handling**: Seamlessly handles file extensions in any case.
- **Post-Processing Actions**: Optionally delete files from the GoPro's SD card after transfer and remove non-supported video files from the local directory.
- **Robust Logging**: Detailed logs are maintained for monitoring and troubleshooting.
- **Error Handling**: Comprehensive validation ensures configurations are correct, preventing unexpected behaviors.

## Prerequisites

Ensure your system meets the following requirements before installation:

- **Operating System**: Linux-based (e.g., Ubuntu, Debian)
- **Shell**: Bash
- **Python**: Python 3.x
- **Utilities**:
  - `gphoto2`: For interfacing with the GoPro camera.
  - `jq`: For parsing JSON configuration files.
  - `ffmpeg`: (Assumed for video conversion in the Python script)
- **Permissions**: The script should be run with a user that has the necessary permissions to execute `gphoto2` commands and modify files in the designated directories.

## Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/gopro-transfer-daemon.git
   cd gopro-transfer-daemon
   ```

2. **Install Dependencies**

   Ensure that `gphoto2`, `jq`, and `ffmpeg` are installed on your system.

   - **Ubuntu/Debian:**

     ```bash
     sudo apt-get update
     sudo apt-get install -y gphoto2 jq ffmpeg python3-pip
     ```

   - **Other Distributions:**

     Use your distribution's package manager to install the required utilities.

3. **Python Dependencies**

   Install any required Python packages. Assuming your Python script uses standard libraries or specifies dependencies, use `pip` to install them.

   ```bash
   pip3 install -r requirements.txt
   ```

   *Note: Create a `requirements.txt` file listing any Python dependencies if necessary.*

4. **Set Executable Permissions**

   Ensure the shell script has executable permissions.

   ```bash
   chmod +x gopro_transfer_daemon.sh
   ```

5. **Directory Structure**

   Ensure the following directory structure exists:

   ```
   gopro-transfer-daemon/
   ├── gopro_transfer_daemon.sh
   ├── vidconv.py
   ├── transfer_config.json
   ├── conversion_config.json
   └── README.md
   ```

## Configuration

Before running the script, configure the `transfer_config.json` and `conversion_config.json` files to suit your preferences.

### Transfer Configuration

**File:** `transfer_config.json`

**Purpose:** Define settings related to file transfer from the GoPro to the local machine.

**Parameters:**

- `delete_from_sd_after` (boolean): If `true`, deletes files from the GoPro's SD card after successful transfer.
- `only_new` (boolean): If `true`, only downloads new files that haven't been transferred before.
- `force_overwrite` (boolean): If `true`, forces overwriting of existing files in the local directory.
- `delete_non_mp4` (boolean): If `true`, deletes non-supported video files from the local directory after transfer.

**Example:**

```json
{
  "delete_from_sd_after": true,
  "only_new": true,
  "force_overwrite": true,
  "delete_non_mp4": false
}
```

### Conversion Configuration

**File:** `conversion_config.json`

**Purpose:** Define settings related to video conversion using the Python script.

**Parameters:**

- `conversion` (boolean): If `true`, enables video conversion.
- `resolution` (string): Desired video resolution (e.g., `"720"`, `"1080"`).
- `bitrate` (string): Desired bitrate level (e.g., `"low"`, `"mid"`, `"high"`).
- `codec` (string): Desired video codec (e.g., `"h264"`, `"h265"`).
- `quality` (integer): Quality level (e.g., `20` for higher quality).
- `crop` (boolean): If `true`, crops the video.
- `remove` (boolean): If `true`, removes the original file after conversion.
- `cut` (array|string|boolean): Defines timestamps for cutting the video.
  - **Array**: `["00:01:30", "00:02:00"]` to cut from 1:30 to 2:00.
  - **String**: `"00:01:30"` to start at 1:30 with a duration defined by `length`.
  - **Boolean**: `false` to disable cutting.
- `length` (float): Duration in minutes for the cut. Only used if `cut` is a single timestamp.
- `rm_audio` (boolean): If `true`, removes audio from the video.
- `keep_gps` (boolean): If `true`, retains GPS data.
- `extract_gpx` (boolean): If `true`, extracts GPX data.
- `bright` (boolean): If `true`, adjusts brightness and saturation.
- `supported_formats` (array): List of supported video file extensions (optional).

**Example with Multiple Cuts:**

```json
{
  "conversion": true,
  "resolution": "720",
  "bitrate": "mid",
  "codec": "h265",
  "quality": 20,
  "crop": true,
  "remove": false,
  "cut": ["00:01:30", "00:02:00"],
  "length": null,
  "rm_audio": true,
  "keep_gps": false,
  "extract_gpx": true,
  "bright": true
}
```

**Example with Single Cut and Length:**

```json
{
  "conversion": true,
  "resolution": "1080",
  "bitrate": "high",
  "codec": "h264",
  "quality": 18,
  "crop": false,
  "remove": true,
  "cut": "00:03:00",
  "length": 2.0,
  "rm_audio": false,
  "keep_gps": true,
  "extract_gpx": false,
  "bright": false
}
```

**Notes:**

- **Supported Video Formats:** The script now supports multiple video file formats, including `.mp4`, `.mkv`, `.avi`, and `.mov`, regardless of their case (e.g., `.MP4`, `.MKV`).
- **`cut` Parameter Constraints:**
  - If `cut` is an array, it must contain **exactly two** timestamps.
  - If `cut` is a single timestamp string, `length` must be specified.
  - Boolean parameters must strictly be `true` or `false`.

## Usage

1. **Connect Your GoPro:**

   Ensure your GoPro is connected to your computer via USB and is in the appropriate mode to allow file transfers.

2. **Run the Shell Script:**

   Execute the shell script to initiate the transfer and conversion process.

   ```bash
   ./gopro_transfer_daemon.sh
   ```

3. **Monitor Logs:**

   The script logs all actions and errors to `/var/log/gopro_transfer_daemon_debug.log`. You can monitor the log in real-time using:

   ```bash
   tail -f /var/log/gopro_transfer_daemon_debug.log
   ```

4. **Automate with Cron (Optional):**

   To automate the script to run at regular intervals, add a cron job.

   ```bash
   crontab -e
   ```

   **Example Cron Entry (Runs every day at 2 AM):**

   ```cron
   0 2 * * * /path/to/gopro_transfer_daemon.sh
   ```

## Script Overview

### Shell Script: `gopro_transfer_daemon.sh`

**Purpose:** Automate the process of transferring supported video files from a GoPro, organizing them into date-specific folders, and initiating video conversion based on defined configurations.

**Key Functions:**

1. **`load_transfer_config`**
   - Loads and validates transfer-related configurations from `transfer_config.json`.
   - Ensures boolean parameters are correctly set.

2. **`load_conversion_config`**
   - Loads and validates conversion-related configurations from `conversion_config.json`.
   - Handles `cut` parameter flexibly, supporting arrays, single strings, or disabling cutting.
   - Validates mutual exclusivity between multiple `cut` timestamps and `length`.
   - Ensures all boolean parameters are correctly set.
   - Validates timestamp formats.

3. **`create_date_folder`**
   - Creates a date-specific folder in the download directory following the `YYYY-mm-dd` format.
   - Returns the path to the created folder.

4. **`run_video_conversion`**
   - Processes all supported video files (`.mp4`, `.mkv`, `.avi`, `.mov`) in the specified directory.
   - Constructs and executes the Python conversion command with appropriate arguments based on the configuration.
   - Handles case-insensitive file matching.
   - Logs the success or failure of each conversion.

5. **`process_gopro`**
   - Orchestrates the overall workflow:
     - Loads transfer configurations.
     - Creates and navigates to the date-specific download folder.
     - Executes the `gphoto2` command to transfer files.
     - Performs post-transfer actions like deleting files from the SD card or removing non-supported video files.
     - Initiates video conversion if enabled.

**Execution Flow:**

1. **Initialization:**
   - Sets the `PATH`.
   - Defines log file location.
   - Starts logging.

2. **Configuration Loading:**
   - Loads transfer and conversion configurations.

3. **File Transfer:**
   - Transfers all supported video files from the GoPro to the designated local directory.
   - Applies post-transfer actions based on configurations.

4. **Video Conversion:**
   - Converts downloaded video files according to conversion settings.

### Python Script: `vidconv.py`

**Purpose:** Perform video conversion tasks such as adjusting resolution, bitrate, codec, quality, cropping, removing audio, retaining GPS data, extracting GPX data, and adjusting brightness.

**Key Functionalities:**

- **Argument Parsing:**
  - Accepts various command-line arguments to customize video conversion.

- **Video Processing:**
  - Utilizes `ffmpeg` or similar libraries to perform the actual conversion based on provided arguments.

- **Error Handling:**
  - Validates input arguments and handles processing errors gracefully.

**Usage Example:**

```bash
python3 /home/admin/vidconv.py input.mp4 --resolution 720 --bitrate mid --codec h265 --quality 20 --crop --rm_audio --keep_gps --extract_gpx --cut 00:01:30 00:02:00 --bright
```

**Note:** Ensure that the Python script is executable and correctly located at `/home/admin/vidconv.py` or update the shell script accordingly.

## Logging

All actions, including successes and errors, are logged to `/var/log/gopro_transfer_daemon_debug.log`. This log file is invaluable for monitoring the script's performance and diagnosing issues.

**Accessing Logs:**

```bash
tail -f /var/log/gopro_transfer_daemon_debug.log
```

**Log Entries Include:**

- Script start and completion times.
- Execution of `gphoto2` commands.
- Success or failure of file transfers.
- Initiation and outcome of video conversions.
- Any errors encountered during processing.

## Troubleshooting

**1. Script Fails to Create Download Directory**

- **Error Message:**

  ```
  Error: Failed to create directory /home/admin/GoPro
  ```

- **Solution:**
  - Ensure the user running the script has write permissions to `/home/admin`.
  - Check for existing directory permissions and adjust if necessary.

**2. Configuration File Not Found**

- **Error Message:**

  ```
  Error: Transfer configuration file not found at /home/admin/GoPro/transfer_config.json
  ```

- **Solution:**
  - Verify that the configuration files exist at the specified paths.
  - Ensure correct filenames and extensions.
  - Check file permissions to allow the script to read them.

**3. Invalid Configuration Values**

- **Error Message:**

  ```
  Error: Invalid value for CONVERSION_ENABLED in conversion_config.json. Must be 'true' or 'false'.
  ```

- **Solution:**
  - Open the respective configuration file.
  - Ensure all boolean parameters are set to `true` or `false` without quotes.
  - Validate JSON syntax using tools like `jq`.

**4. No Supported Video Files Found**

- **Log Entry:**

  ```
  No video files found in /home/admin/GoPro/2024-04-27. Skipping conversion.
  ```

- **Solution:**
  - Confirm that the GoPro has video files with supported extensions (`.mp4`, `.mkv`, `.avi`, `.mov`).
  - Check if the GoPro is correctly connected and in the right mode for file transfer.
  - Verify `gphoto2` connectivity.

**5. Video Conversion Errors**

- **Error Message:**

  ```
  Error: Conversion failed for file 'video.mp4' with exit status 1
  ```

- **Solution:**
  - Review the Python script's logs or error messages for specific issues.
  - Ensure all required Python dependencies are installed.
  - Validate that the Python script has executable permissions.
  - Check for sufficient disk space and system resources.

**6. Permissions Issues**

- **Symptoms:**
  - Unable to execute scripts.
  - Cannot delete or modify files.

- **Solution:**
  - Ensure the user has the necessary permissions to execute scripts and modify files in the target directories.
  - Adjust file permissions using `chmod` and ownership using `chown` as needed.

## Contributing

Contributions are welcome! Whether it's bug fixes, feature enhancements, or documentation improvements, your input helps make this project better for everyone.

**Steps to Contribute:**

1. **Fork the Repository**

2. **Create a New Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**

4. **Commit Your Changes**

   ```bash
   git commit -m "Add feature: your-feature-name"
   ```

5. **Push to Your Fork**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**

   Provide a clear description of your changes and the reasons behind them.

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute this software as per the terms of the license.

---

*For any further questions or assistance, feel free to reach out to the project maintainer at [youremail@example.com](mailto:youremail@example.com).*
```

---

## How to Create and Download the README

Since I cannot provide direct download links, you can easily create the `README.md` file yourself by following these steps:

1. **Open a Terminal or Command Prompt:**

   Navigate to the root directory of your project where you want the `README.md` file to reside.

2. **Create the `README.md` File:**

   Use a text editor like `nano`, `vim`, or any GUI-based editor. Here's how to do it using `nano`:

   ```bash
   nano README.md
   ```

3. **Paste the README Content:**

   Copy the entire content from the markdown block above (everything between the ```markdown and ``` lines) and paste it into the `nano` editor.

4. **Save and Exit:**

   - If you're using `nano`, press `CTRL + O` to write out the changes, then press `Enter` to confirm.
   - Press `CTRL + X` to exit the editor.

5. **Verify the File:**

   List the files in the directory to ensure `README.md` has been created.

   ```bash
   ls -l README.md
   ```

6. **View the README (Optional):**

   You can view the content of the README using:

   ```bash
   cat README.md
   ```

   Or, for a paginated view:

   ```bash
   less README.md
   ```

## Additional Tips

- **GitHub Integration:**

  If you're using GitHub, committing and pushing the `README.md` file to your repository will render it automatically on the repository's main page.

  ```bash
  git add README.md
  git commit -m "Add comprehensive README"
  git push origin main
  ```

- **Editing in the Future:**

  You can always update the `README.md` by reopening it in your preferred text editor and making the necessary changes.

- **Markdown Preview:**

  To view the formatted README, consider using a Markdown preview tool or editor that supports live previews, such as:

  - **VS Code:** Offers built-in Markdown preview (`CTRL + Shift + V`).
  - **Atom:** Has Markdown preview packages available.
  - **Online Editors:** Websites like [Dillinger](https://dillinger.io/) allow you to paste and view Markdown content instantly.

If you encounter any issues or have further questions while setting up the README or your project, feel free to ask!
