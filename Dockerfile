# ---- Build Stage ----
#17-jre-jammy gets updated if the JDK is changed (21 or something else) --uses Ubuntu 22.04
    FROM eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /app

COPY . .

# Package is redundant but needed in case dockerfile is removed to outside pipeline
RUN ./mvnw package -DskipTests 

# ---- Run Stage ----
    #17-jre-jammy gets updated if the JDK is changed (21 or something else)
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
