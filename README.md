# 自用高可用k8s-1.18基础环境搭建+java应用环境+备份脚本
# 基础环境包含
环境初始化bash脚本（使用阿里云的镜像资源）\
calico网络插件\
带管理权限的dashboard\
Metrics Server 
# 拓展资源清单包含
kafka集群\
单点redis\
traefik2.2.1（启用了带basicAuth加密的控制台）\
单点EFK7.5.2（带X-PACK）\
前端静态文件使用的nginx（NFS挂载模式，生产建议直接把静态文件也打成镜像，这里不应该暴露业务内容）
# 使用helm部署
nfs-client-provisioner \
prometheus（已写入支持traefik指标的job）\
grafana（grafana修改为ssl模式，如果不需要请直接原版的清单，其实完全可以用traefik暴露时ssl）\
kafka-manager

#引用 \
kafka集群原出处 \
https://github.com/Yolean/kubernetes-kafka \
使用的备份还原脚本原出处 \
http://blog.csdn.net/ygqygq2
