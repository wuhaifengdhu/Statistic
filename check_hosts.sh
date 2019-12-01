#!/bin/bash
#
# --------------------------------------------------------------------------------------------------------------
#
#
#   Author: wuhaifengdhu@163.com
#
#   Demo shell script to description several key points in writhing shell script.
#
# --------------------------------------------------------------------------------------------------------------
# Environment variable
# --------------------------------------------------------------------------------------------------------------
HOSTS_FILE="hosts.txt"
SLC="slc"
ANALYTIC_FILE="detail.txt"
# --------------------------------------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------
# Functions
# --------------------------------------------------------------------------------------------------------------

function usage() {
    echo "$0 [-a]"
    echo "Usage: "
    echo -e "\t Get dns name for each host from IP"
    echo -e "\t -a Analysis the count of hosts for each cluster"
    echo -e "\t -h Print help message"
    echo -e "Sample: $0  Running command without any argument will check host name for each ip and print in console"
    echo -e "Sample: $0 -a  Running command to further analysis the hosts number for each cluster"
}

# ------------------------------Logical for get dns from ip address---------------------------------------------

function get_hosts() {
    host=$1
    echo ${host##*/}
}

function get_host_dns() {
    host=$1
    dns=$(nslookup ${host} | grep name | awk -F\  '{print $NF}' | sed 's/.$//')
    [[ -z ${dns} ]] && echo "dcg14_${host}" || echo ${dns%%.*}
}

function setup_free_ssh() {
    for host in `cat ${HOSTS_FILE}` ; do
        host_ip=$(get_hosts ${host})
        echo "check connection to ${host_ip}"
        ssh-copy-id ${host_ip}
    done
}

function check_hosts() {
    for host in `cat ${HOSTS_FILE}` ; do
        host_ip=$(get_hosts ${host})
        echo -e "${host_ip}\t$(get_host_dns ${host_ip})"
    done
}

# -------------------------Logical for analysis ----------------------------------------------------------------

function analysis() {
    get_dns_hosts > ${ANALYTIC_FILE}
    clusters=("dcg12" "dcg13" "dcg14" "slca" "slcb")
    for cluster_name in "${clusters[@]}" ; do
        if [[ ${cluster_name} == ${SLC}* ]]; then
            analysis_slc_cluster ${cluster_name} ${ANALYTIC_FILE}
        else
            analysis_dcg_cluster ${cluster_name} ${ANALYTIC_FILE}
        fi
    done
    analysis_unknown_cluster ${ANALYTIC_FILE}
}

function analysis_dcg_cluster() {
    cluster_name=$1
    content_file=$2
    partition_num=$(cat ${content_file} | grep "^${cluster_name}" | wc -l)
    host_num=$(cat ${content_file} | grep "^${cluster_name}" | sort | uniq | wc -l)
    echo -e "${cluster_name}\t${host_num}\t${partition_num}"
}

function analysis_slc_cluster() {
    cluster_name=$1
    content_file=$2
    slc_cluster=$(get_last_char ${cluster_name})
    partition_num=$(cat ${content_file} | grep "^${SLC}" | grep "${slc_cluster}$" | wc -l)
    host_num=$(cat ${content_file} | grep "^${SLC}" | grep "${slc_cluster}$" | sort | uniq | wc -l)
    echo -e "${cluster_name}\t${host_num}\t${partition_num}"
}

function analysis_unknown_cluster() {
    content_file=$1
    host_list=$(cat ${content_file} | grep -v dcg | grep -v slc)
    echo "Other host not in list:"
    cat ${content_file} | grep -v dcg | grep -v slc
    echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
}

function get_dns_hosts() {
    for host in `cat ${HOSTS_FILE}` ; do
        host_ip=$(get_hosts ${host})
        echo "$(get_host_dns ${host_ip})"
    done
}

function get_last_char() {
    name=$1
    echo ${name: -1}
}

# --------------------------------------------------------------------------------------------------------------
# Shell flow
# --------------------------------------------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    check_hosts
    exit 0
fi

while getopts ":ah" opt
do
    case ${opt} in
        a)
        analysis
        break
        ;;
        h)
        usage
        break
        ;;
        ?)
        usage
        break
    esac
done

