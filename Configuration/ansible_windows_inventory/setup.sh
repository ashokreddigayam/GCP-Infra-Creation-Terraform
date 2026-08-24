#!/bin/bash
# ==============================================================================
# SETUP SCRIPT: setup.sh (for Linux/Mac control machines)
# PURPOSE: Install Ansible and required collections
# ==============================================================================

set -e

echo "============================================================"
echo "Windows Infrastructure Ansible Setup"
echo "============================================================"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required. Please install Python 3.9+"
    exit 1
fi

echo "✓ Python found: $(python3 --version)"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required. Please install pip3"
    exit 1
fi

echo "✓ pip3 found"
echo ""

# Install Ansible
echo "Installing Ansible..."
pip3 install --upgrade ansible
echo "✓ Ansible installed: $(ansible --version | head -1)"
echo ""

# Install required collections
echo "Installing Ansible collections..."
ansible-galaxy install -r requirements.yml -v
echo "✓ Collections installed"
echo ""

# Create vars directory if not exists
if [ ! -d "vars" ]; then
    mkdir -p vars
    echo "✓ Created vars directory"
fi

# Make scripts executable
chmod +x scripts/*.ps1 2>/dev/null || true
echo "✓ Scripts permissions updated"
echo ""

echo "============================================================"
echo "Setup Complete!"
echo "============================================================"
echo ""
echo "Next steps:"
echo "1. Edit inventory.ini with your server IPs/hostnames"
echo "2. Configure WinRM on Windows servers"
echo "3. Test connectivity: ansible -i inventory.ini source_server -m win_ping"
echo "4. Run workflow: ansible-playbook run-complete-workflow.yml"
echo ""
echo "For more information, see README.md"
