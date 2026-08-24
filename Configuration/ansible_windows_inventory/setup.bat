@echo off
REM ==============================================================================
REM SETUP SCRIPT: setup.bat (for Windows control machines)
REM PURPOSE: Install Ansible and required collections
REM ==============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo Windows Infrastructure Ansible Setup
echo ============================================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.9+ from python.org
    echo.
    pause
    exit /b 1
)

echo Python found:
python --version
echo.

REM Check if pip is installed
pip --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: pip is not installed
    echo Please ensure pip is installed with Python
    echo.
    pause
    exit /b 1
)

echo pip found:
pip --version
echo.

REM Install Ansible
echo Installing Ansible...
pip install --upgrade ansible
if errorlevel 1 (
    echo.
    echo ERROR: Failed to install Ansible
    echo.
    pause
    exit /b 1
)

echo.
ansible --version | findstr /r "ansible"
echo.

REM Install required collections
echo Installing Ansible collections...
ansible-galaxy install -r requirements.yml -v
if errorlevel 1 (
    echo.
    echo WARNING: Some collections may have failed to install
    echo Try running: ansible-galaxy install ansible.windows community.windows
    echo.
)

echo Collections installation completed
echo.

REM Create vars directory if not exists
if not exist "vars" (
    mkdir vars
    echo Created vars directory
    echo.
)

echo ============================================================
echo Setup Complete!
echo ============================================================
echo.
echo Next steps:
echo 1. Edit inventory.ini with your server IPs/hostnames
echo 2. Configure WinRM on Windows servers
echo 3. Test connectivity: ansible -i inventory.ini source_server -m win_ping
echo 4. Run workflow: ansible-playbook run-complete-workflow.yml
echo.
echo For more information, see README.md
echo.

pause
