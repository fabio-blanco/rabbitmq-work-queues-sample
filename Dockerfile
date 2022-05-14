# syntax=docker/dockerfile:1.3

#FROM openjdk:17-jdk-slim as base
FROM eclipse-temurin:17-jdk-focal as base

WORKDIR /app

COPY gradle/ gradle
COPY gradlew settings.gradle ./
COPY buildSrc/build.gradle ./buildSrc/
COPY consumer/build.gradle ./consumer/
COPY producer/build.gradle ./producer/
RUN ./gradlew build || return 0
COPY . .

# NOTE: we cant run two gradle instances on the same terminal because they don't behave well.
#       if there is the need to run a second worker for concorrence, open aother terminal manually
#       and run it from there.
FROM base as development
#CMD ./gradlew --no-daemon --no-build-cache -q run --debug-jvm -p consumer --args="worker1" # I don't know why the remote connection is not working
RUN ./gradlew build
CMD cd consumer/build/classes/java/main/ && java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 -cp .:/root/.gradle/caches/modules-2/files-2.1/com.rabbitmq/amqp-client/5.14.2/a8093a297829385ff3dec39aa1c8730a2af1fdc2/amqp-client-5.14.2.jar:\
/root/.gradle/caches/modules-2/files-2.1/org.slf4j/slf4j-api/1.7.32/cdcff33940d9f2de763bc41ea05a0be5941176c3/slf4j-api-1.7.32.jar \
br/com/globalbyte/samples/rabbit/wq/Worker Work Hard...

FROM base as build
RUN ["./gradlew", "jar"]

FROM eclipse-temurin:17-jre-focal as production

COPY execute.sh .
RUN chmod +x execute.sh
COPY --from=build /app/consumer/build/libs/consumer-*.jar consumer.jar
COPY --from=build /app/producer/build/libs/producer-*.jar producer.jar

ENTRYPOINT ["./execute.sh"]