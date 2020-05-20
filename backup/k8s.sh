#!/usr/bin/env bash
##############################################################
# File Name: ut_backup_k8s.sh
# Version: V1.0
# Author: Chinge_Yang
# Blog: http://blog.csdn.net/ygqygq2
# Created Time : 2018-09-18 09:13:55
# Description:
##############################################################

#获取脚本所存放目录
cd `dirname $0`
bash_path=`pwd`

#脚本名
me=$(basename $0)
# delete dir and keep days
delete_dirs=("/data/backup/kubernetes:7")
backup_dir=/data/backup/kubernetes
files_dir=("/etc/kubernetes" "/var/lib/kubelet/pki")
kubelet_config="/var/lib/kubelet/config.yaml"
kubeadm_flags="/var/lib/kubelet/kubeadm-flags.env"
log_dir=$backup_dir/log
shell_log=$log_dir/${USER}_${me}.log
ssh_port="22"
ssh_parameters="-o StrictHostKeyChecking=no -o ConnectTimeout=60"
ssh_command="ssh ${ssh_parameters} -p ${ssh_port}"
scp_command="scp ${ssh_parameters} -P ${ssh_port}"
DATE=$(date +%F)
BACK_SERVER="127.0.0.1"  # 远程备份服务器IP
BACK_SERVER_BASE_DIR="/data/backup"
BACK_SERVER_DIR="$BACK_SERVER_BASE_DIR/kubernetes/${HOSTNAME}"  # 远程备份 服务器 目录
BACK_SERVER_LOG_DIR="$BACK_SERVER_BASE_DIR/kubernetes/logs"

#定义保存日志函数
function save_log () {
    echo -e "`date +%F\ %T` $*" >> $shell_log
}

save_log "start backup mysql"

[ ! -d $log_dir ] && mkdir -p $log_dir

#定义输出颜色函数
function red_echo () {
#用法:  red_echo "内容"
    local what=$*
    echo -e "\e[1;31m ${what} \e[0m"
}

function green_echo () {
#用法:  green_echo "内容"
    local what=$*
    echo -e "\e[1;32m ${what} \e[0m"
}

function yellow_echo () {
#用法:  yellow_echo "内容"
    local what=$*
    echo -e "\e[1;33m ${what} \e[0m"
}

function twinkle_echo () {
#用法:  twinkle_echo $(red_echo "内容")  ,此处例子为红色闪烁输出
    local twinkle='\e[05m'
    local what="${twinkle} $*"
    echo -e "${what}"
}

function return_echo () {
    [ $? -eq 0 ] && green_echo "$* 成功" || red_echo "$* 失败" 
}

function return_error_exit () {
    [ $? -eq 0 ] && REVAL="0"
    local what=$*
    if [ "$REVAL" = "0" ];then
        [ ! -z "$what" ] && green_echo "$what 成功"
    else
        red_echo "$* 失败，脚本退出"
        exit 1
    fi
}

#定义确认函数
function user_verify_function () {
    while true;do
        echo ""
        read -p "是否确认?[Y/N]:" Y
        case $Y in
    [yY]|[yY][eE][sS])
        echo -e "answer:  \\033[20G [ \e[1;32m是\e[0m ] \033[0m"
        break   
        ;;
    [nN]|[nN][oO])
        echo -e "answer:  \\033[20G [ \e[1;32m否\e[0m ] \033[0m"          
        exit 1
        ;;
      *)
        continue
        ;;
        esac
    done
}

#定义跳过函数
function user_pass_function () {
    while true;do
        echo ""
        read -p "是否确认?[Y/N]:" Y
        case $Y in
            [yY]|[yY][eE][sS])
            echo -e "answer:  \\033[20G [ \e[1;32m是\e[0m ] \033[0m"
            break   
            ;;
            [nN]|[nN][oO])
            echo -e "answer:  \\033[20G [ \e[1;32m否\e[0m ] \033[0m"          
            return 1
            ;;
            *)
            continue
            ;;
            esac
    done
}

function backup () {
    for f_d in ${files_dir[@]}; do
        f_name=$(basename ${f_d})
        d_name=$(dirname $f_d)
        cd $d_name
        tar -cjf ${f_name}.tar.bz $f_name
        if [ $? -eq 0 ]; then
            file_size=$(du ${f_name}.tar.bz|awk '{print $1}')
            save_log "$file_size ${f_name}.tar.bz"
            save_log "finish tar ${f_name}.tar.bz"
        else
            file_size=0
            save_log "failed tar ${f_name}.tar.bz"
        fi
        rsync -avzP ${f_name}.tar.bz  $backup_dir/$(date +%F)-${f_name}.tar.bz
        rm -f ${f_name}.tar.bz
    done

    export ETCDCTL_API=3
    etcdctl --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        snapshot save $backup_dir/$(date +%F)-k8s-snapshot.db
    cd $backup_dir
    tar -cjf $(date +%F)-k8s-snapshot.tar.bz $(date +%F)-k8s-snapshot.db 
    if [ $? -eq 0 ]; then
        file_size=$(du $(date +%F)-k8s-snapshot.tar.bz|awk '{print $1}')
        save_log "$file_size ${f_name}.tar.bz"
        save_log "finish tar ${f_name}.tar.bz"
    else
        file_size=0
        save_log "failed tar ${f_name}.tar.bz"
    fi
    rm -f $(date +%F)-k8s-snapshot.db
}

function rsync_backup_files () {
    # 传输日志文件
    #传输到远程服务器备份, 需要配置免密ssh认证
    $ssh_command root@${BACK_SERVER} "mkdir -p ${BACK_SERVER_DIR}/${DATE}/"
    rsync -avz --bwlimit=5000 -e "${ssh_command}" $backup_dir/*.bz \
    root@${BACK_SERVER}:${BACK_SERVER_DIR}/${DATE}/
    [ $? -eq 0 ] && save_log "success rsync" || \
      save_log "failed rsync"
}

function delete_old_files () {
    for delete_dir_keep_days in ${delete_dirs[@]}; do
        delete_dir=$(echo $delete_dir_keep_days|awk -F':' '{print $1}')
        keep_days=$(echo $delete_dir_keep_days|awk -F':' '{print $2}')
        [ -n "$delete_dir" ] && cd ${delete_dir}
        [ $? -eq 0 ] && find -L ${delete_dir} -mindepth 1 -mtime +$keep_days -exec rm -rf {} \;
    done
}

backup
delete_old_files
#rsync_backup_files
mkdir $backup_dir/kubelet
cp $kubelet_config $backup_dir/kubelet
cp $kubeadm_flags $backup_dir/kubelet
 
save_log "finish $0\n"

exit 0
