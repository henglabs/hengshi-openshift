#! /bin/bash

source ${HSDATA}/engine-cluster/export-cluster.sh
yes | gpstart -m
PGOPTIONS="-cgp_session_role=utility" psql postgres -c "set allow_system_table_mods='dml'; update gp_segment_configuration set hostname='localhost', address='localhost'"
PGOPTIONS="-cgp_session_role=utility" psql postgres -c "select * from gp_segment_configuration"
yes | gpstop -M fast &> /dev/null
echo "after config docker engine standalone"
