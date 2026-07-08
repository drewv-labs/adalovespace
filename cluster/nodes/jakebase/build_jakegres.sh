#!/bin/bash
set -euxo pipefail
source sudo-check

cluster=/opt/adalovespace/cluster
jakepsql=${cluster}/nodes/jakebase/psql

${cluster}/core/debian/mods/install_postgresql.sh

${jake}/config_host_settings.sh
${jake}/config_database.sh
${jake}/config_users.sh
${jake}/config_tables.sh
