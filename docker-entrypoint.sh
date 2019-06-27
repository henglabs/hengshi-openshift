#! /bin/bash

fix_conf() {
    test -e ${HSHOME}/conf/engine-segment-hosts || cp ${HSHOME}/conf/engine-segment-hosts.sample ${HSHOME}/conf/engine-segment-hosts
}

check_start() {
    echo "HSDATA: ${HSDATA}"
    n=$(ls ${HSDATA} | wc -l)
    echo "ls ${HSDATA}: [ $(ls ${HSDATA}) ], files: $n"
    if [ ! -e ${HSDATA}/pg_data ]; then
        echo "ERROR: not exist -> ${HSDATA}/pg_data"
        exit 1
    fi

    if [ ! -e ${HSDATA}/engine-cluster ]; then
        echo "ERROR: not exist -> ${HSDATA}/engine-cluster"
        exit 1
    fi
}

export_env_to_conf() {
    local conf=${HSHOME}/conf/hengshi-sense-env.sh
    cp ${conf}.sample ${conf}
    sed -i -e "$ a HS_HENGSHI_DATA=${HSDATA}" -e "$ a HS_BACKUP_DIR=${HSDATA}/backup" ${conf}
    env | sed -r '/^TERM=/d; /^LS_COLORS=/d; /^HOSTNAME=/d; /^PATH=/d; /^PWD=/d; /^SHLVL=/d; /^HOME=/d; /^LANG=/d; /^FIX_GP_HOST=/d; /^_=/d; s/(.*)=(.*)/export \1=\2/' >> ${conf}
}

update_gpdb_conf() {
    cd ${HSHOME}/bin && source common.sh &> /dev/null
    if [ -e ${GREENPLUM_DATA}/export-cluster.sh ];then
        sed -i -e "s=/gpdb-.*-centos7-cluster/=/${GREENPLUM_DIR}/=" ${GREENPLUM_DATA}/export-cluster.sh
    fi
}

main() {
    sudo chown hengshi:hengshi ${HSDATA} -R
    action="$1"
    module="$2"
    fix_conf
    export_env_to_conf
    update_gpdb_conf
    
    if [[ "$action" == "start" ]]; then
        check_start
        touch ${HSHOME}/logs/nangaparbat.log
        ${HSHOME}/bin/hengshi-sense-bin $*
        if [ -e ${HSHOME}/bin/log_extract.py ]; then
            tail -f ${HSHOME}/logs/nangaparbat.log | ${HSHOME}/bin/log_extract.py
        else
            tail -f ${HSHOME}/logs/nangaparbat.log
        fi
    elif [[ "$action" == "init" ]]; then
        ${HSHOME}/bin/hengshi-sense-bin $*
        if [[ "$module" == "all" ]] || [[ "$module" == "engine" ]]; then
            /fix-hostname.sh
        fi
    else
        ${HSHOME}/bin/hengshi-sense-bin $*
    fi
}

# ===== main =====
if [[ "${BASH_SOURCE[0]}" == "$0" ]];then
  main $*
fi
