FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace

# Copy Gradle wrapper & settings first (caching)
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew

# Copy the rest of the project
COPY . .

# Build the JAR (skip tests for speed in dev)
RUN ./gradlew --no-daemon clean build -x test


# -------- Runtime --------
FROM alpine:3.20 AS runtime

RUN apk add --no-cache openjdk21-jre
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"


WORKDIR /app

# Copy built JAR from the *build* stage
COPY --from=build /workspace/build/libs/*.jar app.jar

EXPOSE 8080

# Default profile; override with -e SPRING_PROFILES_ACTIVE=dev if needed
ENV SPRING_PROFILES_ACTIVE=dev

# Run the app
CMD ["sh","-c","exec java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75 -jar /app/app.jar --spring.profiles.active=${SPRING_PROFILES_ACTIVE}"]
