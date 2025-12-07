
#!/bin/bash

################################################################################
#                                                                              #
#  AWS MGN/DRS Pre-Installation Requirements Validator                        #
#  Version: 1.0                                                                #
#  Purpose: Standalone validation of AWS MGN/DRS installation requirements    #
#                                                                              #
################################################################################

# Script configuration
SCRIPT_VERSION="1.0"
OUTPUT_FILE="/var/log/aws-mgn-validation-$(date +%Y%m%d-%H%M%S).log"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize counters
issues_found=0
warnings_list=()

# Detect OS type
detect_os() {
    local OS_TYPE=""
    local OS_VERSION=""
    local OS_MAJOR=""

    if grep -q "Oracle Linux" /etc/os-release 2>/dev/null || [ -f /etc/oracle-release ]; then
        OS_TYPE="oracle"
        OS_VERSION=$(grep -oP '(?<=VERSION_ID=")[0-9]+\.[0-9]+' /etc/os-release 2>/dev/null)
        if [ -z "$OS_VERSION" ] && [ -f /etc/oracle-release ]; then
            OS_VERSION=$(grep -oP '(?<=release )[0-9]+\.[0-9]+' /etc/oracle-release 2>/dev/null)
        fi
        OS_MAJOR=$(echo $OS_VERSION | cut -d'.' -f1)
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="rhel"
        OS_VERSION=$(grep -oP '(?<=release )[0-9]+\.[0-9]+' /etc/redhat-release 2>/dev/null)
        OS_MAJOR=$(echo $OS_VERSION | cut -d'.' -f1)
    elif [ -f /etc/debian_version ]; then
        if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
            OS_TYPE="ubuntu"
            OS_VERSION=$(grep -oP '(?<=VERSION_ID=")[0-9]+\.[0-9]+' /etc/os-release 2>/dev/null)
        else
            OS_TYPE="debian"
            OS_VERSION=$(cat /etc/debian_version 2>/dev/null)
        fi
        OS_MAJOR=$(echo $OS_VERSION | cut -d'.' -f1)
    elif [ -f /etc/SuSE-release ] || [ -f /etc/SUSE-brand ]; then
        OS_TYPE="suse"
        OS_VERSION=$(grep -oP '(?<=VERSION_ID=")[0-9]+\.[0-9]+' /etc/os-release 2>/dev/null)
        OS_MAJOR=$(echo $OS_VERSION | cut -d'.' -f1)
    elif grep -q "Amazon Linux" /etc/os-release 2>/dev/null; then
        OS_TYPE="amazon"
        OS_VERSION=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release 2>/dev/null)
        OS_MAJOR=$OS_VERSION
    else
        OS_TYPE="unknown"
    fi

    echo "$OS_TYPE|$OS_VERSION|$OS_MAJOR"
}

# Main validation function
validate_requirements() {
    local output_file="$1"
    
    # Detect OS
    local os_info=$(detect_os)
    local OS_TYPE=$(echo $os_info | cut -d'|' -f1)
    local OS_VERSION=$(echo $os_info | cut -d'|' -f2)
    local OS_MAJOR=$(echo $os_info | cut -d'|' -f3)

    {
        echo ""
        echo "################################################################################"
        echo "#                                                                              #"
        echo "#     AWS MGN/DRS INSTALLATION REQUIREMENTS VALIDATION                         #"
        echo "#                                                                              #"
        echo "################################################################################"
        echo ""
        echo "Validation Date: $(date +"%Y-%m-%d %H:%M:%S")"
        echo "Operating System: $OS_TYPE $OS_VERSION"
        echo "Reference: docs.aws.amazon.com/mgn/latest/ug/installation-requirements.html"
        echo ""
        echo "================================================================================"
        echo ""

        # 1. Python Installation
        echo "1.  PYTHON INSTALLATION"
        echo "    Requirement: Python 2.4+ or Python 3.0+"
        
        python_version=$(python --version 2>&1 | grep -oP 'Python \K[0-9]+\.[0-9]+\.[0-9]+' || python3 --version 2>&1 | grep -oP 'Python \K[0-9]+\.[0-9]+\.[0-9]+')

        if [ -n "$python_version" ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: Python version $python_version is installed"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: Python is not installed"
            echo "    Remediation:"
            case "$OS_TYPE" in
                rhel|oracle|amazon) echo "      sudo yum install python3" ;;
                ubuntu|debian) echo "      sudo apt install python3" ;;
                suse) echo "      sudo zypper install python3" ;;
                *) echo "      Install Python using your package manager" ;;
            esac
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 2. Build Tools
        echo "2.  BUILD TOOLS VALIDATION"
        echo "    Requirement: make, gcc, perl, tar, gawk, rpm"

        missing_tools=()
        for tool in make gcc perl tar gawk rpm; do
            if ! command -v $tool &> /dev/null; then
                missing_tools+=($tool)
            fi
        done

        if [ ${#missing_tools[@]} -eq 0 ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: All required build tools are installed"
        else
            echo "    Status: ⚠️  WARNING"
            echo "    Details: Missing tools: ${missing_tools[*]}"
            warnings_list+=("Missing build tools: ${missing_tools[*]}")
            echo "    Note: Installer will attempt to install these automatically"
            echo "    Remediation (if auto-install fails):"
            case "$OS_TYPE" in
                rhel|oracle|amazon) echo "      sudo yum install ${missing_tools[*]}" ;;
                ubuntu|debian) echo "      sudo apt install ${missing_tools[*]}" ;;
                suse) echo "      sudo zypper install ${missing_tools[*]}" ;;
                *) echo "      Install ${missing_tools[*]} using your package manager" ;;
            esac
        fi
        echo ""

        # 3. Root Directory Disk Space
        echo "3.  ROOT DIRECTORY DISK SPACE"
        echo "    Requirement: Minimum 2 GB free space on root directory (/)"

        root_free=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
        root_free=$(echo "$root_free" | cut -d'.' -f1)

        if [ "$root_free" -ge 2 ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: Root directory has ${root_free}GB free space"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: Root directory has only ${root_free}GB free space (minimum 2GB required)"
            echo "    Remediation: Free up disk space on the root partition"
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 4. /tmp Directory Space
        echo "4.  /TMP DIRECTORY SPACE"
        echo "    Requirement: Minimum 500 MB free space on /tmp"
        
        tmp_free_mb=$(df -BM /tmp | tail -1 | awk '{print $4}' | sed 's/M//')
        
        if [ "$tmp_free_mb" -ge 500 ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: /tmp has ${tmp_free_mb}MB free space"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: /tmp has only ${tmp_free_mb}MB free space (minimum 500MB required)"
            echo "    Remediation: Free up space on /tmp or increase partition size"
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 5. /tmp Mount Options
        echo "5.  /TMP MOUNT OPTIONS"
        echo "    Requirement: /tmp must be mounted read+write with exec option"
        
        tmp_mount=$(mount | grep ' /tmp ')

        if [ -z "$tmp_mount" ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: /tmp is not separately mounted (uses root filesystem)"
        else
            if echo "$tmp_mount" | grep -q "noexec"; then
                echo "    Status: ❌ FAIL"
                echo "    Details: /tmp is mounted with 'noexec' option"
                echo "    Current mount: $tmp_mount"
                echo "    Remediation: sudo mount -o remount,exec /tmp"
                issues_found=$((issues_found + 1))
            elif echo "$tmp_mount" | grep -q "ro"; then
                echo "    Status: ❌ FAIL"
                echo "    Details: /tmp is mounted read-only"
                echo "    Remediation: sudo mount -o remount,rw /tmp"
                issues_found=$((issues_found + 1))
            else
                echo "    Status: ✅ PASS"
                echo "    Details: /tmp is properly mounted with read+write+exec"
            fi
        fi
        echo ""

        # 6. /boot Partition Space
        echo "6.  /BOOT PARTITION SPACE"
        echo "    Requirement: Minimum 50 MB free space if /boot is separate partition"
        
        boot_mount=$(df /boot 2>/dev/null | tail -1)
        root_mount=$(df / 2>/dev/null | tail -1)

        if [ "$(echo $boot_mount | awk '{print $1}')" != "$(echo $root_mount | awk '{print $1}')" ]; then
            boot_free_mb=$(df -BM /boot | tail -1 | awk '{print $4}' | sed 's/M//')
            
            if [ "$boot_free_mb" -ge 50 ]; then
                echo "    Status: ✅ PASS"
                echo "    Details: /boot has ${boot_free_mb}MB free space (separate partition)"
            else
                echo "    Status: ❌ FAIL"
                echo "    Details: /boot has only ${boot_free_mb}MB free (minimum 50MB required)"
                echo "    Remediation: Clean up old kernels or increase /boot partition size"
                issues_found=$((issues_found + 1))
            fi
        else
            echo "    Status: ✅ PASS"
            echo "    Details: /boot is not a separate partition"
        fi
        echo ""

        # 7. GRUB Bootloader
        echo "7.  GRUB BOOTLOADER"
        echo "    Requirement: GRUB 1 or GRUB 2 bootloader"
        
        if command -v grub2-install &> /dev/null || command -v grub-install &> /dev/null || [ -d /boot/grub ] || [ -d /boot/grub2 ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: GRUB bootloader is installed"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: GRUB bootloader not detected"
            echo "    Note: Only GRUB bootloader is supported"
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 8. GPT Partitioning
        echo "8.  GPT PARTITIONING CHECK"
        echo "    Requirement: Machines with GPT must have grub2-pc-modules installed"
        
        has_gpt=$(parted -ls 2>/dev/null | grep -i "Partition Table: gpt")
        
        if [ -n "$has_gpt" ]; then
            case "$OS_TYPE" in
                rhel|oracle|amazon)
                    grub_modules=$(rpm -qa | grep -E 'grub2-pc-modules|grub2-i386-pc')
                    ;;
                ubuntu|debian)
                    grub_modules=$(dpkg -l | grep grub-pc)
                    ;;
                suse)
                    grub_modules=$(rpm -qa | grep grub2-i386-pc)
                    ;;
            esac

            if [ -n "$grub_modules" ]; then
                echo "    Status: ✅ PASS"
                echo "    Details: GPT detected and grub2-pc-modules is installed"
            else
                echo "    Status: ❌ FAIL"
                echo "    Details: GPT partitioning detected but grub2-pc-modules is missing"
                echo "    Remediation:"
                case "$OS_TYPE" in
                    rhel|oracle|amazon) echo "      sudo yum install grub2-pc-modules" ;;
                    ubuntu|debian) echo "      sudo apt install grub-pc" ;;
                    suse) echo "      sudo zypper install grub2-i386-pc" ;;
                    *) echo "      Install grub2-pc-modules using your package manager" ;;
                esac
                issues_found=$((issues_found + 1))
            fi
        else
            echo "    Status: ✅ PASS"
            echo "    Details: No GPT partitioning detected (MBR or other)"
        fi
        echo ""

        # 9. Secure Boot Status
        echo "9.  SECURE BOOT STATUS"
        echo "    Requirement: Secure Boot must be disabled (not supported)"
        
        sb_status=$(mokutil --sb-state 2>/dev/null)
        
        if echo "$sb_status" | grep -qi "disabled"; then
            echo "    Status: ✅ PASS"
            echo "    Details: Secure Boot is disabled"
        elif echo "$sb_status" | grep -qi "enabled"; then
            echo "    Status: ❌ FAIL"
            echo "    Details: Secure Boot is enabled (not supported)"
            echo "    Remediation: Disable Secure Boot in BIOS/UEFI settings"
            issues_found=$((issues_found + 1))
        else
            echo "    Status: ✅ PASS"
            echo "    Details: Unable to determine Secure Boot status (likely disabled or N/A)"
        fi
        echo ""

        # 10. dhclient Package
        echo "10. DHCLIENT PACKAGE"
        echo "    Requirement: dhclient or dhcp-client package installed"
        
        case "$OS_TYPE" in
            rhel|oracle|amazon)
                dhcp_installed=$(rpm -qa | grep -i dhcp)
                ;;
            ubuntu|debian)
                dhcp_installed=$(dpkg -l | grep -i dhcp)
                ;;
            suse)
                dhcp_installed=$(rpm -qa | grep -i dhcp)
                ;;
        esac

        if [ -n "$dhcp_installed" ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: DHCP client package is installed"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: dhclient package is not installed"
            echo "    Remediation:"
            case "$OS_TYPE" in
                rhel|oracle|amazon) echo "      sudo yum install dhclient" ;;
                ubuntu|debian) echo "      sudo apt install isc-dhcp-client" ;;
                suse) echo "      sudo zypper install dhcp-client" ;;
                *) echo "      Install dhclient using your package manager" ;;
            esac
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 11. Kernel Headers
        echo "11. KERNEL HEADERS VALIDATION"
        echo "    Requirement: kernel-devel/linux-headers matching running kernel"
        
        running_kernel=$(uname -r)
        echo "    Running kernel: $running_kernel"

        case "$OS_TYPE" in
            rhel|amazon)
                kernel_devel=$(rpm -qa | grep "kernel-devel-$running_kernel")
                ;;
            oracle)
                kernel_devel=$(rpm -qa | grep -E "kernel-uek-devel.*$(echo $running_kernel | cut -d'-' -f1)|kernel-devel-$running_kernel")
                ;;
            ubuntu|debian)
                kernel_devel=$(dpkg -l | grep "linux-headers-$running_kernel")
                ;;
            suse)
                kernel_devel=$(rpm -qa | grep "kernel-default-devel.*$(echo $running_kernel | cut -d'-' -f1)")
                ;;
        esac

        if [ -n "$kernel_devel" ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: Matching kernel headers found"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: No matching kernel headers found for kernel $running_kernel"
            echo "    Remediation:"
            case "$OS_TYPE" in
                rhel|amazon) echo "      sudo yum install kernel-devel-\$(uname -r)" ;;
                oracle) echo "      sudo yum install kernel-uek-devel-\$(uname -r)" ;;
                ubuntu|debian) echo "      sudo apt install linux-headers-\$(uname -r)" ;;
                suse) echo "      sudo zypper install kernel-default-devel-\$(uname -r)" ;;
                *) echo "      Install kernel headers matching your running kernel" ;;
            esac
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 12. Kernel Headers Directory
        echo "12. KERNEL HEADERS DIRECTORY CHECK"
        echo "    Requirement: Kernel headers directory must not be a symbolic link"
        
        kernel_src_dirs=("/usr/src/kernels/$running_kernel" "/usr/src/linux-headers-$running_kernel")
        symlink_found=false

        for dir in "${kernel_src_dirs[@]}"; do
            if [ -L "$dir" ]; then
                echo "    Status: ❌ FAIL"
                echo "    Details: $dir is a symbolic link"
                echo "    Remediation: Remove symlink and reinstall kernel headers"
                echo "                 rm $dir"
                case "$OS_TYPE" in
                    rhel|amazon) echo "                 sudo yum reinstall kernel-devel-\$(uname -r)" ;;
                    oracle) echo "                 sudo yum reinstall kernel-uek-devel-\$(uname -r)" ;;
                    ubuntu|debian) echo "                 sudo apt install --reinstall linux-headers-\$(uname -r)" ;;
                    suse) echo "                 sudo zypper install -f kernel-default-devel-\$(uname -r)" ;;
                esac
                symlink_found=true
                issues_found=$((issues_found + 1))
                break
            fi
        done

        if [ "$symlink_found" = false ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: Kernel headers directories are not symbolic links"
        fi
        echo ""

        # 13. User Permissions
        echo "13. USER PERMISSIONS"
        echo "    Requirement: User must be root or in sudoers list"
        
        if [ "$(id -u)" -eq 0 ]; then
            echo "    Status: ✅ PASS"
            echo "    Details: Running as root user"
        elif sudo -n true 2>/dev/null; then
            echo "    Status: ✅ PASS"
            echo "    Details: User has sudo privileges"
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: User is not root and does not have sudo privileges"
            echo "    Remediation: Run script as root or add user to sudoers"
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 14. LVM2 and Device Mapper
        echo "14. LVM2 AND DEVICE MAPPER"
        echo "    Requirement: LVM2 and device-mapper packages installed"
        echo "    Additional: lvm2-2.03.23-1.el9 or later for RHEL/Oracle ≤ 9.4"

        if command -v lvm &> /dev/null && command -v dmsetup &> /dev/null; then
            echo "    Status: ✅ PASS"
            echo "    Details: LVM2 and device-mapper are installed"

            if [[ "$OS_TYPE" == "rhel" || "$OS_TYPE" == "oracle" ]] && [[ -n "$OS_MAJOR" ]] && [[ "$OS_MAJOR" -le 9 ]]; then
                lvm_version=$(rpm -q lvm2 2>/dev/null | grep -oP 'lvm2-\K[0-9]+\.[0-9]+\.[0-9]+')

                if [ -n "$lvm_version" ]; then
                    lvm_major=$(echo $lvm_version | cut -d'.' -f1)
                    lvm_minor=$(echo $lvm_version | cut -d'.' -f2)
                    lvm_patch=$(echo $lvm_version | cut -d'.' -f3)

                    if [[ "$lvm_major" -lt 2 ]] || \
                       ([[ "$lvm_major" -eq 2 ]] && [[ "$lvm_minor" -lt 3 ]]) || \
                       ([[ "$lvm_major" -eq 2 ]] && [[ "$lvm_minor" -eq 3 ]] && [[ "$lvm_patch" -lt 23 ]]); then
                        echo "    Note: ⚠️  LVM version $lvm_version detected (minimum 2.03.23 recommended for RHEL/Oracle ≤ 9.4)"
                        echo "    Recommendation: sudo yum update lvm2"
                        warnings_list+=("LVM version $lvm_version is older than recommended 2.03.23 for RHEL/Oracle ≤ 9.4")
                    else
                        echo "    Note: LVM version $lvm_version meets recommended requirements"
                    fi
                fi
            fi
        else
            echo "    Status: ❌ FAIL"
            echo "    Details: LVM2 or device-mapper is missing"
            echo "    Remediation:"
            case "$OS_TYPE" in
                rhel|oracle|amazon) echo "      sudo yum install lvm2 device-mapper" ;;
                ubuntu|debian) echo "      sudo apt install lvm2" ;;
                suse) echo "      sudo zypper install lvm2 device-mapper" ;;
                *) echo "      Install lvm2 and device-mapper using your package manager" ;;
            esac
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 14.5 Free RAM
        echo "14.5 FREE RAM VALIDATION"
        echo "     Requirement: Minimum 300 MB free RAM"
        
        free_ram=$(free -m | awk 'NR==2{print $7}')
        
        if [ "$free_ram" -ge 300 ]; then
            echo "     Status: ✅ PASS"
            echo "     Details: ${free_ram}MB free RAM available"
        else
            echo "     Status: ❌ FAIL"
            echo "     Details: Only ${free_ram}MB free RAM (minimum 300MB required)"
            echo "     Remediation: Free up memory or add more RAM to the system"
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 14.6 System Architecture
        echo "14.6 SYSTEM ARCHITECTURE"
        echo "     Requirement: x86_64 architecture only (32-bit not supported)"

        arch=$(uname -m)

        if [[ "$arch" == "x86_64" ]]; then
            echo "     Status: ✅ PASS"
            echo "     Details: System architecture is $arch (64-bit, supported)"
        elif [[ "$arch" == "i386" ]] || [[ "$arch" == "i686" ]]; then
            echo "     Status: ❌ FAIL"
            echo "     Details: 32-bit architecture detected ($arch)"
            echo "     Note: AWS MGN does not support 32-bit versions of Linux"
            echo "     Remediation: Migrate to a 64-bit (x86_64) operating system"
            issues_found=$((issues_found + 1))
        else
            echo "     Status: ❌ FAIL"
            echo "     Details: Unsupported architecture detected ($arch)"
            echo "     Note: AWS MGN only supports x86_64 (64-bit) architecture"
            echo "     Remediation: AWS MGN cannot be installed on this architecture"
            issues_found=$((issues_found + 1))
        fi
        echo ""

        # 15. SELinux Status
        echo "15. SELINUX STATUS"
        echo "    Note: SELinux can interfere with agent installation"
        
        selinux_status=$(getenforce 2>/dev/null)
        
        if [ "$selinux_status" == "Disabled" ]; then
            echo "    Status: ✅ OK"
            echo "    Details: SELinux is disabled"
        elif [ "$selinux_status" == "Permissive" ]; then
            echo "    Status: ⚠️  WARNING"
            echo "    Details: SELinux is in permissive mode"
            warnings_list+=("SELinux is in permissive mode")
        elif [ "$selinux_status" == "Enforcing" ]; then
            echo "    Status: ⚠️  WARNING"
            echo "    Details: SELinux is in enforcing mode"
            echo "    Note: Monitor audit logs if installation issues occur"
            warnings_list+=("SELinux is in enforcing mode - Monitor audit logs if issues occur")
        else
            echo "    Status: ℹ️  INFO"
            echo "    Details: SELinux not detected"
        fi
        echo ""

        # 16. fapolicyd Status
        echo "16. FAPOLICYD STATUS (RHEL 8+ SPECIFIC - NOT IN AWS DOCS)"
        echo "    Note: fapolicyd can silently block PyInstaller applications"

        if command -v systemctl &> /dev/null && systemctl list-unit-files 2>/dev/null | grep -q fapolicyd; then
            if systemctl is-active --quiet fapolicyd 2>/dev/null; then
                echo "    Status: ⚠️  WARNING"
                echo "    Details: fapolicyd is RUNNING and may block installation"
                echo "    Impact: Can cause silent failure with exit code 1, no logs created"
                echo "    Recommendation:"
                echo "      1. Check denials: sudo ausearch -m FANOTIFY -ts recent"
                echo "      2. Stop temporarily: sudo systemctl stop fapolicyd"
                echo "      3. Or add to trust: sudo fapolicyd-cli --file add <installer>"
                echo ""
                echo "    ⚠️  Known Issue: May require stopping fapolicyd before installation"
                warnings_list+=("⚠️  fapolicyd is running - May cause silent installation failure")
            else
                echo "    Status: ✅ OK"
                echo "    Details: fapolicyd installed but not running"
            fi
        else
            echo "    Status: ✅ OK"
            echo "    Details: fapolicyd not installed"
        fi
        echo ""

        # 17. Existing Agent Check
        echo "17. EXISTING AGENT CHECK"

        if [ -d "/opt/aws/mgn" ] || [ -d "/opt/aws/drs" ]; then
            echo "    Status: ⚠️  WARNING"
            echo "    Details: AWS Replication Agent directory exists"
            warnings_list+=("AWS Replication Agent directory already exists")
        else
            echo "    Status: ✅ OK"
            echo "    Details: No existing agent installation"
        fi
        echo ""

                # 18. Comprehensive Kernel Validation
        echo "18. KERNEL VALIDATION"
        echo "    Requirement: Kernel versions 2.6.18-164 to 6.8 supported"
        echo "    Additional: Oracle Linux requires UEK Release 3+ or RHCK"
        echo "    Additional: Ubuntu/Debian requires Kernel 3.x or above"

        kernel_version=$(echo $running_kernel | cut -d'-' -f1)
        kernel_major=$(echo $kernel_version | cut -d'.' -f1)
        kernel_minor=$(echo $kernel_version | cut -d'.' -f2)
        kernel_patch=$(echo $kernel_version | cut -d'.' -f3)

        if [[ "$kernel_version" == "4.9.256" ]]; then
            echo "    Status: ❌ FAIL"
            echo "    Details: Kernel version 4.9.256 is explicitly not supported"
            echo "    Remediation: Upgrade to a supported kernel version"
            issues_found=$((issues_found + 1))
        elif [[ "$kernel_version" == "2.6.32-71" ]]; then
            echo "    Status: ❌ FAIL"
            echo "    Details: Kernel version 2.6.32-71 is not supported (RHEL/CentOS 6.0)"
            echo "    Remediation: Upgrade to a supported kernel version"
            issues_found=$((issues_found + 1))
        elif [[ "$kernel_major" -eq 2 ]] && [[ "$kernel_minor" -eq 6 ]] && [[ "$kernel_patch" -lt 18 ]]; then
            echo "    Status: ❌ FAIL"
            echo "    Details: Kernel version $kernel_version is too old (minimum 2.6.18-164)"
            echo "    Remediation: Upgrade to kernel 2.6.18-164 or later"
            issues_found=$((issues_found + 1))
        elif [[ "$kernel_major" -gt 6 ]] || ([[ "$kernel_major" -eq 6 ]] && [[ "$kernel_minor" -gt 8 ]]); then
            echo "    Status: ⚠️  WARNING"
            echo "    Details: Kernel version $kernel_version may not be supported (maximum 6.8)"
            echo "    Note: AWS MGN supports kernel versions up to 6.8"
            warnings_list+=("Kernel version $kernel_version may not be supported (maximum 6.8)")
        elif [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "debian" ]] && [[ "$kernel_major" -lt 3 ]]; then
            echo "    Status: ❌ FAIL"
            echo "    Details: Kernel version $kernel_version is too old for Ubuntu/Debian (minimum 3.x)"
            echo "    Remediation: Upgrade to kernel 3.x or higher"
            issues_found=$((issues_found + 1))
        else
            echo "    Status: ✅ PASS"
            echo "    Details: Kernel version $kernel_version is supported"
        fi

        # Oracle Linux specific UEK check
        if [[ "$OS_TYPE" == "oracle" ]]; then
            running_kernel_full=$(echo $running_kernel)

            if echo "$running_kernel_full" | grep -q "uek"; then
                uek_version=$(echo "$running_kernel_full" | grep -oP 'uek\K[0-9]+' || echo "unknown")

                if [[ "$OS_MAJOR" -eq 9 ]] && [[ "$uek_version" != "unknown" ]] && [[ "$uek_version" -lt 7 ]]; then
                    echo "    Oracle Linux Note: ❌ FAIL"
                    echo "    Details: Oracle Linux 9.x requires UEK Release 7 or RHCK"
                    echo "    Current: UEK Release $uek_version"
                    echo "    Remediation: Upgrade to UEK Release 7 or switch to RHCK"
                    issues_found=$((issues_found + 1))
                elif [[ "$OS_MAJOR" -ge 6 ]] && [[ "$uek_version" != "unknown" ]] && [[ "$uek_version" -lt 3 ]]; then
                    echo "    Oracle Linux Note: ❌ FAIL"
                    echo "    Details: Oracle Linux $OS_VERSION requires UEK Release 3 or higher"
                    echo "    Current: UEK Release $uek_version"
                    echo "    Remediation: Upgrade to UEK Release 3 or higher"
                    issues_found=$((issues_found + 1))
                else
                    echo "    Oracle Linux Note: Running UEK Release $uek_version (supported)"
                fi
            else
                echo "    Oracle Linux Note: Running Red Hat Compatible Kernel"
            fi
        fi
        echo ""

        # Summary
        echo "================================================================================"
        echo ""
        echo "VALIDATION SUMMARY"
        echo "================================================================================"
        echo ""

        if [ "${issues_found:-0}" -eq 0 ]; then
            echo "✅ ALL CHECKS PASSED"
            echo ""
            echo "Your system meets all AWS MGN/DRS installation requirements."
            echo "You can proceed with the agent installation."
            echo ""
        else
            echo "❌ ISSUES FOUND: $issues_found"
            echo ""
            echo "Your system has $issues_found issue(s) that must be resolved before installation."
            echo ""
            echo ""
            echo "Review all failures marked with ❌ FAIL above and apply recommended remediations."
            echo ""
        fi

        if [ ${#warnings_list[@]} -gt 0 ]; then
            echo ""
            echo "⚠️  WARNINGS (non-blocking but recommended to address):"
            echo ""
            for warning in "${warnings_list[@]}"; do
                echo "  • $warning"
            done
            echo ""
        fi

        echo "================================================================================"
        echo ""

    } | tee "$output_file"
}

# Main execution
main() {
    echo ""
    echo "AWS MGN/DRS Pre-Installation Requirements Validator v${SCRIPT_VERSION}"
    echo "Starting validation..."
    echo ""

    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "⚠️  WARNING: This script should be run as root for accurate results"
        echo "Some checks may fail or be incomplete without root privileges"
        echo ""
    fi

    # Run validation
    validate_requirements "$OUTPUT_FILE"

    echo ""
    echo "Validation complete!"
    echo "Full report saved to: $OUTPUT_FILE"
    echo ""
}

# Run main function
main
