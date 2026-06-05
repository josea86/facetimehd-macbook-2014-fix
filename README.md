# facetimehd-linux-installer

A simple Bash script to automate the installation of the Broadcom/iSight webcam (`facetimehd`) driver on MacBook Pro/Air laptops running Debian, Ubuntu, or derivative distributions.

Linux distributions don't include the proprietary firmware required for this webcam out of the box. This script handles the dependencies, downloads the official Boot Camp files from Apple, extracts the sensor calibration data, and compiles the driver.

## What it does
* Installs required build tools and kernel headers.
* Downloads the Boot Camp package directly from Apple's servers.
* Unpacks `AppleCamera64.exe` and extracts the `.dat` calibration files using `dd`.
* Clones and builds the `bcwc_pcie` driver from source.
* Adds `facetimehd` to `/etc/modules` so it loads automatically on boot.

## How to use

Make the script executable and run it:

`chmod +x camara_web.sh`
`./camara_web.sh`

## Keeping it updated

If your system receives a major Linux kernel update in the future, the camera might stop working. If that happens, just run the script again to recompile the driver against your new kernel headers.

## Credits

This script is just an automation wrapper around the work done by patjak and the community. It pulls the source code from their repositories:

* patjak/facetimehd-firmware
* patjak/bcwc_pcie
