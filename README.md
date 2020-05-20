# 自用k8s-1.18基础环境搭建+java应用环境
# 基础环境包含环境初始化bash脚本（使用阿里云的镜像资源）、calico网络插件、带管理权限的dashboard、Metrics Server
# 拓展资源清单包含kafka集群（使用来自https://github.com/Yolean/kubernetes-kafka的清单）、单点redis（开发代码未支持k8s集群的redis）、traefik2.2.1（启用了带basicAuth加密的控制台）、单点EFK7.5.2（带X-PACK）、前端静态文件使用的nginx（NFS挂载模式，生产建议直接把静态文件也打成镜像，这里不应该暴露业务内容）
# 使用helm部署的nfs-client-provisioner、prometheus（已写入支持traefik指标的job）、grafana（grafana修改为ssl模式，如果不需要请直接原版的清单，其实完全可以用traefik暴露时ssl，清单是traefik会用之前写的）kafka-manager
