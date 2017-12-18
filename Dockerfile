FROM java:openjdk-8-jdk-alpine

MAINTAINER info.inspectit@novatec-gmbh.de

ENV INSPECTIT_VERSION 1.8.5.101
ENV GRADLE_VERSION 3.4

COPY dumb-init /dumb-init

RUN apk --no-cache add ca-certificates wget libstdc++ \
 && wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.22-r5/glibc-2.22-r5.apk \
 && apk --allow-untrusted add glibc-2.22-r5.apk \
 && wget --no-check-certificate -O /master.zip https://github.com/ContinuITy-Project/inspectIT/archive/master.zip \
 && unzip /master.zip -d . \
 && rm *.apk \
 && rm /master.zip

ENV GRADLE_HOME /usr/local/gradle
ENV PATH ${PATH}:${GRADLE_HOME}/bin

# Install gradle
WORKDIR /usr/local
RUN wget  https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip && \
    unzip gradle-$GRADLE_VERSION-bin.zip && \
    rm -f gradle-$GRADLE_VERSION-bin.zip && \
    ln -s gradle-$GRADLE_VERSION gradle && \
echo -ne "- with Gradle $GRADLE_VERSION\n" >> /root/.built

RUN mv /inspectIT-master /inspectit.root

# Build inspectit.server
WORKDIR /inspectit.root
RUN /bin/sh /usr/local/gradle/bin/gradle -q inspectit.server:release
RUN unzip /inspectit.root/inspectit.server/build/release/packages/inspectit-cmr.linux* -d /

WORKDIR /CMR

VOLUME ["/CMR/config", "/CMR/db", "/CMR/storage", "/CMR/ci"]

EXPOSE 8182 9070

COPY run.sh run.sh
CMD /bin/sh run.sh
HEALTHCHECK --interval=15s CMD wget http://localhost:8182/rest/cmr/version -qO /dev/null || exit 1
