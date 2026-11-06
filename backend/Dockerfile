FROM gradle:8.14-jdk21-alpine AS build
WORKDIR /workspace
COPY settings.gradle.kts build.gradle.kts ./
COPY src src
RUN gradle bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S oyla && adduser -S oyla -G oyla
USER oyla
COPY --from=build /workspace/build/libs/*.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
