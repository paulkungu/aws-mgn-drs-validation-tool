# AWS MGN/DRS Pre-Installation Requirements Validator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

A standalone validation tool that checks all AWS Application Migration Service (MGN) and Disaster Recovery Service (DRS) installation requirements before attempting agent installation—preventing silent failures and saving troubleshooting time.

## 🎯 Purpose

This tool proactively validates all 20+ installation requirements documented by AWS, plus critical undocumented checks (like fapolicyd on RHEL 8+), providing clear visual indicators and actionable remediation steps.

## ⚡ Quick Start

```bash
# Download the script
curl -O https://raw.githubusercontent.com/paulkungu/aws-mgn-drs-validation-tool/main/validate-mgn-drs-requirements.sh

# Make it executable
chmod +x validate-mgn-drs-requirements.sh

# Run validation (requires root or sudo)
sudo ./validate-mgn-drs-requirements.sh

```
🔍 # What It Checks
# Official AWS Requirements

## Based on [AWS MGN Installation Requirements](https://docs.aws.amazon.com/mgn/latest/ug/installation-requirements.html) and [Supported Operating Systems Linux]([https://docs.aws.amazon.com/mgn/latest/ug/Supported-Operating-Systems.html](https://docs.aws.amazon.com/mgn/latest/ug/Supported-Operating-Systems.html#Supported-Operating-Systems-Linux)):

    ✅ Python 2.4+ or 3.0+
    ✅ Build tools (make, gcc, perl, tar, gawk, rpm)
    ✅ Disk space (root, /tmp, /boot)
    ✅ /tmp mount options (exec permission)
    ✅ GRUB bootloader
    ✅ Kernel headers matching running kernel
    ✅ LVM2 and device-mapper
    ✅ Free RAM (minimum 300MB)
    ✅ System architecture (x86_64 only)
    ✅ Kernel version compatibility



📊 Visual Status Indicators

    ✅ PASS - Requirement met, no action needed
    ❌ FAIL - Critical issue that must be fixed before installation
    ⚠️ WARNING - Non-blocking but recommended to address

🖥️ Supported Operating Systems

    Red Hat Enterprise Linux (RHEL) 6.x - 9.x
    Oracle Linux 6.x - 9.x
    Amazon Linux & AL2 AL2023
    Ubuntu 14.04 - 22.04
    Debian 8 - 11
    SUSE Linux Enterprise Server 12 - 15

🙏 Acknowledgments

    Developed in response to AWS Support Cases
    Inspired by the AWS Labs MGN/DRS System Details Tool
    Enhanced with automated validation and visual indicators

📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
