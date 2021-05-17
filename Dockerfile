# Maven Builder.
FROM maven:3-jdk-11 as build

ARG TARGET_DIR=dspace-installer
ARG DSPACE_REFSPEC=dspace-7.0-beta5

WORKDIR /app

RUN useradd dspace \
  && mkdir /home/dspace \
  && chown -Rv dspace: /home/dspace

RUN apt-get update && apt-get install git rsync && \
  git clone --depth 1 --branch ${DSPACE_REFSPEC} https://github.com/DSpace/DSpace.git /tmpDSpace && \
  rsync -a /tmpDSpace/ /app/

COPY build/config/local.cfg /app/local.cfg
RUN mkdir /install && \
  chown -Rv dspace: /install && \
  chown -Rv dspace: /app

USER dspace
RUN mvn package && \
  mv /app/dspace/target/${TARGET_DIR}/* /install && \
  mvn clean


# Ant Commands.
FROM tomcat:8-jdk11 as ant_build
ARG TARGET_DIR=dspace-installer
COPY --from=build /install /dspace-src
WORKDIR /dspace-src

ENV ANT_VERSION 1.10.9
ENV ANT_HOME /tmp/ant-$ANT_VERSION
ENV PATH $ANT_HOME/bin:$PATH

RUN mkdir $ANT_HOME && \
  wget -qO- "https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C $ANT_HOME && \
  ant init_installation update_configs update_code update_webapps


# Deployment Image
FROM tomcat:8-jdk11

ENV DSPACE_INSTALL /dspace
ENV DSPACE_BIN $DSPACE_INSTALL/bin/dspace

COPY --from=ant_build /dspace $DSPACE_INSTALL

COPY build/config/local.cfg $DSPACE_INSTALL/config/local.cfg
COPY build/scripts /scripts

RUN apt-get update && apt-get --yes install netcat && \
  ln -s $DSPACE_INSTALL/webapps/server /usr/local/tomcat/webapps/server

EXPOSE 8080 8009
ENV JAVA_OPTS=-Xmx4096m

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
  org.opencontainers.image.source="https://github.com/unb-libraries/unbscholar.dspace.lib.unb.ca"
