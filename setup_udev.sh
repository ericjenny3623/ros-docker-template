# This script needs to be run as root on your machine (the one that will be using the Phidgets)

export UDEV_RULES_DIR=/etc/udev/rules.d
export PHIDGETS_RULES_FILE=99-libphidget22.rules

# Save the current directory
CURRENT_DIR=$(pwd)

# Check if udev rules directory exists
if [ ! -d "$UDEV_RULES_DIR" ]; then
    echo "Udev rules directory does not exist: $UDEV_RULES_DIR"
    exit 1
fi

cd "$UDEV_RULES_DIR"
# Check if udev rules file exists
if [ ! -f "$PHIDGETS_RULES_FILE" ]; then
    touch "$PHIDGETS_RULES_FILE"
    # WARNING: setting MODE="666" is a security risk but should be okay in this case since 
    # this is limited to Phidgets devices only
    echo "SUBSYSTEMS==\"usb\", ACTION==\"add\", ATTRS{idVendor}==\"06c2\", ATTRS{idProduct}==\"00[3-a][0-f]\", MODE=\"666\"" > "$PHIDGETS_RULES_FILE"
fi


