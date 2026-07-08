#!/bin/bash
set -euxo pipefail
source sudo-check

echo "=== Configuring JakeBase PostgreSQL Host"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
entry = "host    all             all             0.0.0.0/0               md5"
if ! grep -qF -- "$entry" /etc/postgresql/*/main/pg_hba.conf; then
    echo "$entry" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
fi

sudo systemctl restart postgresql
echo ""
