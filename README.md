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
## 🔍 What It Checks
### Official AWS Requirements

#### Based on [AWS MGN Installation Requirements](https://docs.aws.amazon.com/mgn/latest/ug/installation-requirements.html) and [Supported Operating Systems Linux](https://docs.aws.amazon.com/mgn/latest/ug/Supported-Operating-Systems.html#Supported-Operating-Systems-Linux):

1. ✅ **Python Installation** - Python 2.4+ or 3.0+
2. ✅ **Build Tools** - make, gcc, perl, tar, gawk, rpm
3. ✅ **Root Directory Space** - Minimum 2GB free
4. ✅ **/tmp Directory Space** - Minimum 500MB free
5. ✅ **/tmp Mount Options** - Must have exec permission
6. ✅ **/boot Partition Space** - Minimum 50MB if separate partition
7. ✅ **GRUB Bootloader** - GRUB 1 or GRUB 2 required
8. ✅ **GPT Partitioning** - grub2-pc-modules for GPT systems
9. ✅ **Secure Boot** - Must be disabled
10. ✅ **dhclient Package** - Required for network configuration
11. ✅ **Kernel Headers** - Must match running kernel version
12. ✅ **Kernel Headers Directory** - Must not be a symbolic link
13. ✅ **User Permissions** - Root or sudo access required
14. ✅ **LVM2 and Device Mapper** - Required packages with version check
15. ✅ **SELinux Status** - Warning if enforcing mode
16. 🛑 **fapolicyd Status** - Detects if fapolicyd may silently block installation
17. ✅ **Free RAM** - Minimum 300MB
18. ✅ **Existing Agent Check** - Warns if AWS Replication Agent directory already exists
19. ✅ **System Architecture** - x86_64 only, 32-bit not supported 
20. ✅ **Kernel Version Compatibility** 

📊 Visual Status Indicators

    ✅ PASS - Requirement met, no action needed
    ❌ FAIL - Critical issue that must be fixed before installation
    ⚠️ WARNING - Non-blocking but recommended to address

🖥️ Supported Operating Systems

    Red Hat Enterprise Linux (RHEL) 6.x - 9.x
    Oracle Linux 6.x - 9.x
    Amazon Linux 1, 2 & 2023
    Ubuntu 14.04 - 22.04
    Debian 8 - 11
    SUSE Linux Enterprise Server 12 - 15

## 📋 Sample Output

```
================================================================================
VALIDATION SUMMARY
================================================================================

❌ ISSUES FOUND: 2

Your system has 2 issue(s) that must be resolved before installation.

Review all failures marked with ❌ FAIL above and apply recommended remediations.

⚠️ WARNINGS (non-blocking but recommended to address):

  • LVM version 2.03.14 is older than recommended 2.03.23 for RHEL/Oracle ≤ 9.4
  • SELinux is in enforcing mode - Monitor audit logs if issues occur
  • ⚠️ fapolicyd is running - May cause silent installation failure

================================================================================
```


🚀 Use Cases

    Pre-migration validation for AWS MGN/DRS projects
    CI/CD pipeline integration for automated checks
    Quick health checks on target migration servers
    Compliance verification before agent deployment
    Troubleshooting installation failures
    
🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

🙏 Acknowledgments

    Developed in response to AWS Support Cases
    Inspired by the AWS Labs MGN/DRS System Details Tool
    Enhanced with automated validation and visual indicators

📝 License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/paulkungu/aws-mgn-drs-validation-tool/blob/main/LICENSE) file for details.

📞 Support

For issues, questions, or contributions, please open an issue on GitHub.
