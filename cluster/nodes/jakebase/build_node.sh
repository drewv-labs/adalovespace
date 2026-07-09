#!/bin/bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

cluster=${ADA_ROOT}/cluster
debmods=${cluster}/debian/mods
jakebase=${cluster}/nodes/jakebase

${debmods}/base_tune.sh
${debmods}/base_installs.sh

${jakebase}/build_jakenfaces.sh  # JakeNFaceS: NFS Host
${jakebase}/build_jakegresql.sh  # JakegreSQL: PostgreSQL Host
${jakebase}/build_jakeskeett.sh  # JakeSkeett: Mosquitto Broker
${jakebase}/build_jakegester.sh  # JakeGester: Telegraf MQTT->PSQL Ingestion Engine
${jakebase}/build_janktifyme.sh  # JanktifyMe: Ntfy Server for MQTT:ada/alerts/# topics

${debmods}/apt_update_upgrade_slay.sh

sudo reboot
