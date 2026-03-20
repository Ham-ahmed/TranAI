#!/bin/sh

# Configuration
#########################################
plugin="TranslatorProAI"
git_url="https://raw.githubusercontent.com/Ham-ahmed/TranAI/refs/heads/main/TranslatorProAI-v3.0"
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/TranslatorProAI"
package="enigma2-plugin-extensions-$plugin"
targz_file="$plugin.tar.gz"
url="$git_url/$targz_file"
temp_dir="/tmp"

# Check internet connection
#########################################
check_internet() {
    wget -q --spider http://google.com
    if [ $? -ne 0 ]; then
        echo "> No internet connection. Please check your network and try again."
        sleep 3
        exit 1
    fi
}

# Get version
#########################################
get_version() {
    version_file="$git_url/version"
    version=$(wget --no-check-certificate -qO- "$version_file" | awk 'NR==1')
    if [ -z "$version" ]; then
        echo "> Failed to get version information. Using default."
        version="3.0"
    fi
    echo "$version"
}

# Determine package manager
#########################################
if command -v dpkg > /dev/null 2>&1; then
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
        echo "> Removing package old version, please wait..."
        sleep 2
        
        # Remove plugin directory
        rm -rf "$plugin_path" > /dev/null 2>&1
        
        # Remove package if installed
        if grep -q "$package" "$status_file" 2>/dev/null; then
            echo "> Removing existing $package package, please wait..."
            $uninstall_command "$package" > /dev/null 2>&1
        fi
        
        echo "*******************************************"
        echo "*        Old version removed successfully  *"
        echo "*******************************************"
        sleep 2
    fi
}

# Download and install package
#########################################
download_and_install_package() {
    version=$(get_version)
    echo "> Downloading $plugin-$version package, please wait ..."
    sleep 2
    
    # Create temp directory if not exists
    mkdir -p "$temp_dir"
    
    # Download with retry mechanism
    max_retries=3
    retry_count=0
    download_success=0
    
    while [ $retry_count -lt $max_retries ]; do
        if wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"; then
            download_success=1
            break
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo "> Download failed. Retrying ($retry_count/$max_retries)..."
                sleep 3
            fi
        fi
    done
    
    if [ $download_success -eq 0 ]; then
        echo "> Package download failed after $max_retries attempts."
        echo "> Please check:"
        echo "  1. Internet connection"
        echo "  2. URL accessibility: $url"
        echo "  3. Server status"
        sleep 4
        return 1
    fi
    
    # Extract package
    echo "> Extracting package..."
    tar -xzf "$temp_dir/$targz_file" -C /
    extract_status=$?
    
    # Clean up temp file
    rm -f "$temp_dir/$targz_file" > /dev/null 2>&1
    
    if [ $extract_status -eq 0 ]; then
        echo "*******************************************"
        echo "*     $plugin-$version installed successfully  *"
        echo "*******************************************"
        sleep 3
        return 0
    else
        echo "> Package extraction failed. The downloaded file may be corrupted."
        sleep 3
        return 1
    fi
}

# Clean up unnecessary files and folders
#########################################
cleanup() {
    # Remove temporary files
    rm -rf /CONTROL > /dev/null 2>&1
    rm -f /control /postinst /preinst /prerm /postrm > /dev/null 2>&1
    rm -f /tmp/*.ipk /tmp/*.tar.gz > /dev/null 2>&1
    
    # Remove any partial downloads
    rm -f "$temp_dir/$targz_file" > /dev/null 2>&1
    
    echo "> Cleanup completed"
    sleep 1
}

# Main execution
#########################################
main() {
    echo "*******************************************"
    echo "*     Starting $plugin installation     *"
    echo "*******************************************"
    echo ""
    
    # Check internet connection
    check_internet
    
    # Remove old version
    check_and_remove_package
    
    # Download and install new version
    if download_and_install_package; then
        # Clean up only if installation successful
        cleanup
        echo "> Installation completed successfully"
    else
        echo "> Installation failed"
        exit 1
    fi
    
    echo "*******************************************"
    echo "*            Finished                     *"
    echo "*******************************************"
    sleep 2
}

# Run main function
main
exit 0