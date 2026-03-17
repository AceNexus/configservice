FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S app && adduser -S app -G app

COPY build/libs/configservice.jar /app/configservice.jar

RUN chown -R app:app /app

USER app

CMD ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/configservice.jar"]
