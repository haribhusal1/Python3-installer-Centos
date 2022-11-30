#!/bin/bash

# Works on CentOS 7/8

FORCE="-f"

MINOR=${1:-3.9.0}
MAJOR=$(echo $MINOR | cut -d. -f1,2)
CENTOS=$(rpm -E '%{rhel}')

PYTHON=Python-"$MINOR"
PYTHON_DIR="${PYTHON:?}"/
PYTHON_TAR="$PYTHON".tgz

PYTHON_EXE=/usr/local/bin/python"$MAJOR"
PIP_EXE=/usr/local/bin/pip"$MAJOR"

INSTALL_DIR=${2:-/opt}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ -x "$PYTHON_EXE" ]; then
   echo Python "$MINOR" already installed
   read -p "Continue? (y/n): " confirm && [[ $confirm == [yY] ]] || exit 0
fi

echo -e "\n~~~~~~~~~~~~~~~~Python $MINOR Install~~~~~~~~~~~~~~~~"

echo -e "~~~~~~~~Update and install required packages~~~~~~~~\n"

# Make sure packages are up to date
yum -y update

# Install wget
yum -y install wget

# Install packages required by all Python versions
yum -y groupinstall "Development Tools"
yum -y install bzip2-devel libffi-devel ncurses-devel

echo -e "\n~~~~~~~~~~~~~~~~~Get Python package~~~~~~~~~~~~~~~~~\n"

cd $INSTALL_DIR || { echo "Could not change to install directory"; exit 2; }

# Download the Python tar
wget https://www.python.org/ftp/python/"$MINOR"/"$PYTHON_TAR"

# Extract the package
tar xvf "$PYTHON_TAR"

# Move to the extracted directory
cd "$PYTHON"/ || { echo "Python directory does not exist"; exit 3; }

echo -e "\n~~~~~~~~~~~~Configure and install Python~~~~~~~~~~~~\n"

# Adjust install for Python3.10+
PY_VER=($(echo $MAJOR | tr "." "\n"))
case $CENTOS in
  7)
    if (( ${PY_VER[0]} > 3 || ${PY_VER[1]} > 9 )); then
      yum install -y -q openssl11 openssl11-devel
      sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
    else
      yum install -y -q openssl openssl-devel
    fi
  ;;
  8)
    yum install -y -q openssl openssl-devel
  ;;
  *)
    echo "Unknown Centos version"
    exit 3
esac

# Setup for Python installation
./configure --enable-optimizations

# Compile Python
sudo make altinstall

# Cleanup
cd ..
rm -r "$PYTHON_TAR"

echo -e "\n~~~~Confirm Python $MINOR and pip installation~~~~\n"

# Confirm installation
"$PYTHON_EXE" --version
"$PIP_EXE" --version
