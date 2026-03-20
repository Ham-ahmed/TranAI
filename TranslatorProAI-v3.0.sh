#!/bin/sh

# Configuration
#########################################
plugin="TranslatorProAI"
git_url="https://raw.githubusercontent.com/Ham-ahmed/TranAI/refs/heads/main/TranslatorProAI-v3.0"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/TranslatorProAI"
package="enigma2-plugin-extensions-$plugin"
targz_file="$plugin.tar.gz"
url="$git_url/$targz_file"
temp_dir="/tmp"

# Determine package manager
#########################################
if command -v dpkg >/dev/null 2>&1; then
    package_manager="apt"
    status_file="/var/lib/dpkg/status"
    uninstall_command="apt-get purge --auto-remove -y"
else
    package_manager="opkg"
    status_file="/var/lib/opkg/status"
    uninstall_command="opkg remove --force-depends"
fi

# Check and remove package old version
#########################################
check_and_remove_package() {
    if [ -d "$plugin_path" ]; then
        echo "> removing package old version please wait..."
        sleep 3
        
        # Remove plugin directory
        rm -rf "$plugin_path" > /dev/null 2>&1
        
        # Remove package if exists in status file
        if grep -q "$package" "$status_file" 2>/dev/null; then
            echo "> Removing existing $package package, please wait..."
            $uninstall_command "$package" > /dev/null 2>&1
        fi
        
        echo "*******************************************"
        echo "*             Removed Finished            *"
        echo "*******************************************"
        sleep 3
    else 
        echo "> No existing installation found"
    fi
}

# Download & install package
#########################################
download_and_install_package() {
    echo "> Downloading $plugin-$version package please wait ..."
    sleep 3
    
    # Download the tar.gz file
    if wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"; then
        # Extract to root directory
        if tar -xzf "$temp_dir/$targz_file" -C / > /dev/null 2>&1; then
            echo "> $plugin-$version package installed successfully"
        else
            echo "> Extraction failed for $plugin-$version package"
            rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1
            sleep 3
            exit 1
        fi
        
        # Clean up
        rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1
        sleep 3
    else
        echo "> Download failed for $plugin-$version package"
        rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1
        sleep 3
        exit 1
    fi
}

# Remove unnecessary files and folders
#########################################
cleanup() {
    # Remove common control files
    rm -rf /CONTROL >/dev/null 2>&1
    rm -f /control /postinst /preinst /prerm /postrm >/dev/null 2>&1
    rm -f /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
    
    # Print completion message
    echo "> [$(date +'%Y-%m-%d')] Installation completed for $plugin"
}

# Main execution
#########################################
echo "*******************************************"
echo "*     Starting $plugin installation     *"
echo "*******************************************"

# Run functions
check_and_remove_package
download_and_install_package
cleanup

echo "*******************************************"
echo "*        Installation Finished            *"
echo "*******************************************"
sleep 2

exit 0