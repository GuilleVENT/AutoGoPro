#!/bin/bash
export PATH=/usr/bin:/bin:/usr/local/bin

LOGFILE="/var/log/gopro_transfer_daemon_debug.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "$(date): Script started"

# Transfer CONFIG file 
TRANSFER_CONFIG_FILE='/home/admin/GoPro/transfer_config.json' 

# Conversion CONFIG file
CONVERSION_CONFIG_FILE='/home/admin/GoPro/conversion_config.json'

# Download directory
DOWNLOAD_DIR='/home/admin/GoPro'

# Conversion py-script 
VIDCONV_SCRIPT=${VIDCONV_SCRIPT:-/home/admin/vidconv.py}

# Ensure the directory exists
if ! mkdir -p "$DOWNLOAD_DIR"; then
    echo "Error: Failed to create directory $DOWNLOAD_DIR" >&2
    exit 1
fi

# Function to validate timestamp format
validate_timestamp() {
    local ts="$1"
    if ! [[ "$ts" =~ ^([0-9]{2}):([0-5][0-9]):([0-5][0-9])$ ]]; then
        echo "Error: Invalid timestamp format '$ts'. Expected HH:MM:SS." >&2
        exit 1
    fi
}

# Function to load transfer config with validation
load_transfer_config() {
    if [[ ! -f "$TRANSFER_CONFIG_FILE" ]]; then
        echo "Error: Transfer configuration file not found at $TRANSFER_CONFIG_FILE" >&2
        exit 1
    fi
    DELETE_FROM_SD_AFTER=$(jq -r '.delete_from_sd_after' "$TRANSFER_CONFIG_FILE")
    ONLY_NEW=$(jq -r '.only_new' "$TRANSFER_CONFIG_FILE")
    FORCE_OVERWRITE=$(jq -r '.force_overwrite' "$TRANSFER_CONFIG_FILE")
    DELETE_NON_MP4=$(jq -r '.delete_non_mp4' "$TRANSFER_CONFIG_FILE")

    # Validate boolean parameters
    for bool_param in DELETE_FROM_SD_AFTER ONLY_NEW FORCE_OVERWRITE DELETE_NON_MP4; do
        eval value=\$$bool_param
        if [[ "$value" != "true" && "$value" != "false" && -n "$value" ]]; then
            echo "Error: Invalid value for $bool_param in transfer_config.json. Must be 'true' or 'false'." >&2
            exit 1
        fi
    done
}

# Function to load conversion config with enhanced CUT handling and validation
load_conversion_config() {
    if [[ ! -f "$CONVERSION_CONFIG_FILE" ]]; then
        echo "Error: Conversion configuration file not found at $CONVERSION_CONFIG_FILE" >&2
        exit 1
    fi
    CONVERSION_ENABLED=$(jq -r '.conversion' "$CONVERSION_CONFIG_FILE")
    RESOLUTION=$(jq -r '.resolution // empty' "$CONVERSION_CONFIG_FILE")
    BITRATE=$(jq -r '.bitrate // empty' "$CONVERSION_CONFIG_FILE")
    CODEC=$(jq -r '.codec // empty' "$CONVERSION_CONFIG_FILE")
    QUALITY=$(jq -r '.quality // empty' "$CONVERSION_CONFIG_FILE")
    CROP=$(jq -r '.crop // empty' "$CONVERSION_CONFIG_FILE")
    REMOVE=$(jq -r '.remove // empty' "$CONVERSION_CONFIG_FILE")
    CUT=$(jq -r '
        if type == "array" then
            .cut | join(" ")
        elif type == "string" then
            .cut
        else
            empty
        end
    ' "$CONVERSION_CONFIG_FILE")
    LENGTH=$(jq -r '.length // empty' "$CONVERSION_CONFIG_FILE")
    RM_AUDIO=$(jq -r '.rm_audio // empty' "$CONVERSION_CONFIG_FILE")
    KEEP_GPS=$(jq -r '.keep_gps // empty' "$CONVERSION_CONFIG_FILE")
    EXTRACT_GPX=$(jq -r '.extract_gpx // empty' "$CONVERSION_CONFIG_FILE")
    BRIGHT=$(jq -r '.bright // empty' "$CONVERSION_CONFIG_FILE")

    CUT_COUNT=0
    if [[ -n "$CUT" ]]; then
        # Count the number of spaces to determine the number of timestamps
        CUT_COUNT=$(echo "$CUT" | wc -w)
    fi

    if [[ "$CUT_COUNT" -gt 2 ]]; then
        echo "Error: '--cut' accepts a maximum of two timestamps." >&2
        exit 1
    fi

    if [[ "$CUT_COUNT" -gt 1 && -n "$LENGTH" ]]; then
        echo "Error: Cannot specify both '--cut' with multiple timestamps and '--length'." >&2
        exit 1
    fi

    # Validate timestamp formats
    if [[ -n "$CUT" ]]; then
        for ts in $CUT; do
            validate_timestamp "$ts"
        done
    fi

    # Validate boolean parameters
    for bool_param in CONVERSION_ENABLED CROP REMOVE RM_AUDIO KEEP_GPS EXTRACT_GPX BRIGHT; do
        eval value=\$$bool_param
        if [[ "$value" != "true" && "$value" != "false" && -n "$value" ]]; then
            echo "Error: Invalid value for $bool_param in conversion_config.json. Must be 'true' or 'false'." >&2
            exit 1
        fi
    done
}

create_date_folder() {
    # Get the current date in YYYY-mm-dd format
    local folder_name=$(date +%Y-%m-%d)

    # Create the folder
    local folder_path="$DOWNLOAD_DIR/$folder_name"
    if [ ! -d "$folder_path" ]; then
        mkdir -p "$folder_path"
    fi

    # Return the folder path
    echo "$folder_path"
}

run_video_conversion() {

    local date_folder="$1"

    echo "$(date): Starting video conversion for files in $date_folder..."

    # Load conversion configurations
    load_conversion_config

    if [[ "$CONVERSION_ENABLED" != "true" ]]; then
        echo "$(date): Video conversion is disabled in the configuration."
        return
    fi

    # Enable case-insensitive and nullglob (no match returns empty array)
    shopt -s nocaseglob nullglob

    # Gather all .mp4 files (case-insensitive)
    mp4_files=("$date_folder"/*.mp4)

    if [[ ${#mp4_files[@]} -eq 0 ]]; then
        echo "$(date): No MP4 files found in $date_folder. Skipping conversion."
        shopt -u nocaseglob nullglob
        return
    fi

    for file in "${mp4_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "$(date): Preparing to convert '$file'..."

            # Initialize the Python command as an array
            PYTHON_CMD=(python3 "$VIDCONV_SCRIPT" "$file")

            # Append arguments conditionally
            [[ -n "$RESOLUTION" ]] && PYTHON_CMD+=(--resolution "$RESOLUTION")
            [[ -n "$BITRATE" ]] && PYTHON_CMD+=(--bitrate "$BITRATE")
            [[ -n "$CODEC" ]] && PYTHON_CMD+=(--codec "$CODEC")
            [[ -n "$QUALITY" ]] && PYTHON_CMD+=(--quality "$QUALITY")
            [[ "$CROP" == "true" ]] && PYTHON_CMD+=(--crop)
            [[ "$REMOVE" == "true" ]] && PYTHON_CMD+=(--remove)
            [[ "$RM_AUDIO" == "true" ]] && PYTHON_CMD+=(--rm_audio)
            [[ "$KEEP_GPS" == "true" ]] && PYTHON_CMD+=(--keep_gps)
            [[ "$EXTRACT_GPX" == "true" ]] && PYTHON_CMD+=(--extract_gpx)
            [[ -n "$CUT" ]] && PYTHON_CMD+=(--cut $CUT)
            [[ -n "$LENGTH" ]] && PYTHON_CMD+=(--length "$LENGTH")
            [[ "$BRIGHT" == "true" ]] && PYTHON_CMD+=(--bright)

            # Log the command being executed
            echo "$(date): Executing command: ${PYTHON_CMD[@]}"

            # Execute the Python command
            "${PYTHON_CMD[@]}"
            exit_status=$?

            if [[ $exit_status -ne 0 ]]; then
                echo "$(date): Error: Conversion failed for file '$file' with exit status $exit_status" >&2
            else
                echo "$(date): Conversion succeeded for file '$file'"
            fi
        fi
    done

    # Disable case-insensitive and nullglob to revert to default behavior
    shopt -u nocaseglob nullglob

    echo "$(date): Video conversion process completed."
}

process_gopro() {
    echo "$(date): GoPro connected. Starting file transfer..."
    load_transfer_config

    # Ensure the download folder for the current date exists
    local date_folder_path=$(create_date_folder)

    # Change to the dated download directory
    if ! cd "$date_folder_path"; then
        echo "Error: Failed to change to directory $date_folder_path" >&2
        exit 1
    fi

    # Construct gphoto2 command 
    CMD="gphoto2 --get-all-files"
    [[ "$FORCE_OVERWRITE" == "true" ]] && CMD="$CMD --force-overwrite"
    [[ "$ONLY_NEW" == "true" ]] && CMD="$CMD --new"

    echo "$(date): Executing command: $CMD"

    # Execute gphoto2 command
    if ! $CMD; then
        echo "Error: Failed to download files from GoPro" >&2
        exit 1
    fi

    echo "$(date): Files successfully downloaded to $date_folder_path"

    # Post-download actions
    if [[ "$DELETE_FROM_SD_AFTER" == "true" ]]; then
        if gphoto2 --folder '/store_00000004/DCIM/100GOPRO' --delete-all-files; then
            echo "$(date): Files removed from the Camera SD Card post download"
        else
            echo "Warning: Failed to delete files from the Camera SD Card" >&2
        fi
    fi

    if [[ "$DELETE_NON_MP4" == "true" ]]; then
        if find "$date_folder_path" -type f ! \( -iname "*.mp4" -o -iname "*.py" -o -iname "*.json" -o -iname "*.sh" \) -delete; then
            echo "$(date): Removed non-MP4 files"
        else
            echo "Warning: Failed to delete non-MP4 files" >&2
        fi
    fi

    # Run video conversion if enabled
    run_video_conversion "$date_folder_path"
}

process_gopro
