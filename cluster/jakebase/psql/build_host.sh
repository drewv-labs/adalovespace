#!/bin/bash

A_NODES=/opt/ada-codespace/nodes
JAKE=${A_NODES}/jakebase

${A_NODES}/_core/debian/install_postgresql.sh

${JAKE}/psql/config_host_settings.sh
${JAKE}/psql/config_database.sh
${JAKE}/psql/config_users.sh
${JAKE}/psql/config_tables.sh
