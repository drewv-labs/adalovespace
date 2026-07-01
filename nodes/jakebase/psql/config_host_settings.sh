#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# This script configures the PostgreSQL server to accept connections from any IP address and uses password authentication.
# It is intended for use with JakeBase, a hypothetical application that requires a PostgreSQL database.

# Install PostgreSQL if not already installed
if ! command -v psql &> /dev/null; then
    echo "!!! PostgreSQL is not installed. Installing now..."
    /opt/ada-codespace/nodes/_core/debian/install_postgresql.sh
fi

echo "=== Configuring JakeBase PostgreSQL Host"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf

entry = "host    all             all             0.0.0.0/0               md5"
if ! grep -qF -- "$entry" /etc/postgresql/*/main/pg_hba.conf; then
    echo "$entry" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
fi

sudo systemctl restart postgresql
echo ""
