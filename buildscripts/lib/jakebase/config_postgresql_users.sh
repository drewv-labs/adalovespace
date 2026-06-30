#!/bin/bash
#
source ${HOME}/adalovespace/cluster.conf

echo "=== Configuring Jakebase PostgreSQL Host Users"

sudo -u postgres psql << 'EOF'
CREATE USER coffee_courier WITH PASSWORD 'coffeecourier';
CREATE USER field_agent WITH PASSWORD 'fieldagent';
EOF
