
# 使用 Dart 官方稳定版镜像
FROM dart:stable

# 设置工作目录
WORKDIR /app

# 将写好的服务端代码复制进容器
COPY server.dart .

# 暴露 2000 端口
EXPOSE 2000

# 启动我们的 API 服务器
CMD ["dart", "run", "server.dart"]
