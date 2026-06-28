#!/bin/bash

add_pg_hba_entry() {
    if ! grep -qF -- "$1" /etc/postgresql/*/main/pg_hba.conf; then
        echo "$1" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
    fi
}

echo "=== Configuring JakeBase PostgreSQL Host"
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
add_pg_hba_entry "host    all             all             0.0.0.0/0               md5"
sudo systemctl restart postgresql
echo ""
