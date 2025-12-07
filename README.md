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

