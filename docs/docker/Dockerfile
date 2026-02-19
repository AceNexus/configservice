# 使用 OpenJDK 21（Alpine 版）作為基礎映像，體積較小且適合容器化部署
FROM eclipse-temurin:21-jre-alpine

# 設定工作目錄為 /app
WORKDIR /app

# 建立非特權使用者，避免以 root 執行應用程式
RUN addgroup -S app && adduser -S app -G app

# 複製編譯後的 JAR 檔案到容器內
COPY configservice.jar /app/configservice.jar

RUN chown -R app:app /app

# 切換為非特權使用者
USER app

# 以 Java 啟動應用程式，設定容器化 JVM 調優參數
CMD ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/configservice.jar"]
