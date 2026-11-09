# Container image for O'FAIRe (https://github.com/agroportal/fairness), the
# FAIRness assessment web service used by OntoPortal. Upstream publishes no image.
#
# Build arg FAIRNESS_REF: a commit SHA or tag of agroportal/fairness. Pin a full SHA
# for reproducible builds.

ARG FAIRNESS_REF=24def6b4b01fb7690e938adfc8477d6436c3cc1f

FROM maven:3.9-eclipse-temurin-11 AS build
ARG FAIRNESS_REF
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/agroportal/fairness.git \
 && git fetch -q --depth 1 origin "${FAIRNESS_REF}" \
 && git checkout -q FETCH_HEAD \
 # pom.xml names web.xml with Windows path separators; make it resolvable on Linux
 && sed -i 's|WebContent\\WEB-INF\\web.xml|WebContent/WEB-INF/web.xml|' pom.xml \
 && mvn -B -q package -DskipTests \
 && git rev-parse HEAD > target/fairness-assessment/FAIRNESS_COMMIT

# Tomcat 9: the servlet uses javax.servlet, which Tomcat 10+ no longer provides.
FROM tomcat:9.0-jre11-temurin
ARG FAIRNESS_REF
LABEL org.opencontainers.image.title="ontoportal-fairness" \
      org.opencontainers.image.description="O'FAIRe FAIRness assessment service for OntoPortal" \
      org.opencontainers.image.licenses="MIT" \
      io.github.agroportal.fairness.ref="${FAIRNESS_REF}"

# Deployed as an exploded ROOT webapp: the portal configuration is read from the
# classpath (WEB-INF/classes/config/portals/<name>/config.properties), and the
# entrypoint writes it there at startup.
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /src/target/fairness-assessment/ /usr/local/tomcat/webapps/ROOT/
# drop the example portal shipped in the sources; only the configured one should exist
RUN rm -rf /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/config/portals/*

COPY entrypoint.sh fairness-cache /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/fairness-cache

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD bash -c '</dev/tcp/127.0.0.1/8080' || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["catalina.sh", "run"]
