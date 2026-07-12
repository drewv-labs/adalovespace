#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

echo "${ADA_BLU1}=== Configuring JakeBase PostgreSQL Host"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
entry = "host    all             all             0.0.0.0/0               md5"

safe-tee-sed "/etc/postgresql/*/main/pg_hba.conf" "^${entry}" "$entry" "yes"

sudo systemctl restart postgresql
echo ""
