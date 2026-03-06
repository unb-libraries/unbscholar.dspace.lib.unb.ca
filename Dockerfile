# Maven Builder.
FROM maven:3-eclipse-temurin-17 AS build

ARG TARGET_DIR=dspace-installer
ARG DSPACE_REFSPEC=dspace-9.2

WORKDIR /app
RUN useradd dspace && \
  mkdir /home/dspace && \
  chown -Rv dspace: /home/dspace

RUN apt-get update && apt-get install -y --no-install-recommends git rsync && \
  git clone --depth 1 --branch ${DSPACE_REFSPEC} https://github.com/DSpace/DSpace.git /tmpDSpace && \
  rsync -a /tmpDSpace/ /app/

COPY build/config/dspace/local.cfg /app/local.cfg
RUN mkdir /install && \
  chown -Rv dspace: /install && \
  chown -Rv dspace: /app

USER dspace
RUN mvn --no-transfer-progress package&& \
  mv /app/dspace/target/${TARGET_DIR}/* /install && \
  mvn clean


# Ant Commands.
FROM eclipse-temurin:17 AS ant_build
ARG TARGET_DIR=dspace-installer
COPY --from=build /install /dspace-src
WORKDIR /dspace-src

ENV ANT_VERSION="1.10.14"
ENV ANT_HOME="/tmp/ant-$ANT_VERSION"
ENV PATH="$ANT_HOME/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends wget && \
  mkdir $ANT_HOME && \
  wget -qO- "https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C $ANT_HOME && \
  ant init_installation update_configs update_code update_webapps


# Deployment Image
FROM tomcat:10.1-jdk17-temurin-jammy

ENV DSPACE_INSTALL="/dspace"
ENV DSPACE_BIN="$DSPACE_INSTALL/bin/dspace"
ENV JAVA_OPTS="-Xmx6g -Xms6g -Dfile.encoding=UTF-8"
ENV RSYNC_FLAGS=""
ENV RSYNC_COPY="rsync -a --inplace --no-compress $RSYNC_FLAGS"
ENV RSYNC_MOVE="$RSYNC_COPY --remove-source-files"

COPY --from=ant_build /dspace $DSPACE_INSTALL
COPY build /build

RUN mkdir -p /etc/postfix && cat /build/config/postfix/main.cf >> /etc/postfix/main.cf && \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get --yes install bsdmainutils netcat-traditional postfix rsync unzip && rm -rf /var/lib/apt/lists/* && \
  postfix start && \
  ln -s $DSPACE_INSTALL/webapps/server /usr/local/tomcat/webapps/server && \
  $RSYNC_MOVE /build/config/dspace/ $DSPACE_INSTALL/config/ && \
  $RSYNC_MOVE /build/scripts/ /scripts

RUN /scripts/install_dspace_cron.sh && \
  /scripts/add_xforward_tomcat.sh && \
  /scripts/install_geoip_db.sh

EXPOSE 8000
EXPOSE 8009

ENTRYPOINT ["/scripts/run.sh"]

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL ca.unb.lib.generator="dspace" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="MIT" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.description="unbscholar.dspace.lib.unb.ca provides object storage for The UNBScholar instance at UNB Libraries." \
  org.label-schema.name="unbscholar.dspace.lib.unb.ca" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/unb-libraries/unbscholar.dspace.lib.unb.ca" \
  org.label-schema.vendor="University of New Brunswick Libraries" \
  org.label-schema.version=$VERSION \
  org.opencontainers.image.authors="libsupport@unb.ca" \
  org.opencontainers.image.source="https://github.com/unb-libraries/unbscholar.dspace.lib.unb.ca"
