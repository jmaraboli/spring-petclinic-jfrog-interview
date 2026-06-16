# ---- Run Stage ----
    #17-jre-jammy gets updated if the JDK is changed (21 or something else)
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]