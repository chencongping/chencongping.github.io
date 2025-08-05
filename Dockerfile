FROM openjdk:17

# 创建非 root 用户并切换（增强安全性）
# Debian系统创建用户组和用户的正确命令
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# 切换到非root用户
USER appuser

# 直接从宿主机的target目录复制打包好的JAR文件
# 前提：宿主机已通过本地Maven打包，target目录存在于项目根目录
COPY target/*.jar /app.jar

# 暴露应用端口
EXPOSE 8080

# 配置Java日志输出到标准输出，便于Docker收集
ENV JAVA_OPTS="-Dlogback.configurationFile=/logback.xml -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"

# 健康检查（根据应用实际情况调整检查路径和频率）
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q --spider http://localhost:10002/actuator/health || exit 1

# 启动命令（合并ENTRYPOINT和CMD，便于传递额外参数）
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app.jar $0 $@"]
CMD []
