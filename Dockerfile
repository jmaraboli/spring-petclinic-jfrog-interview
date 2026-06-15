# ---- Build Stage ----
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

COPY . .

# Package is redundant but needed in case dockerfile is removed to outside pipeline
RUN ./mvnw package -DskipTests 

# ---- Run Stage ----
    #17-jre-alpine gets updated if the JDK is changed (21 or something else)
FROM eclipse-temurin:17-jre-alpine 

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
