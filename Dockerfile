
FROM registry.access.redhat.com/ubi7/ubi:7.7

ENV JBOSS_HOME=/opt/jboss

COPY jboss-eap-7.2.0.zip /tmp/jboss-eap-7.2.0.zip

RUN yum install -y java-11-openjdk java-11-openjdk-devel && \
    yum install -y unzip curl && \
    yum clean all && \
    mkdir -p ${JBOSS_HOME} && \
    useradd -m -s /bin/bash jboss && echo "jboss:password" | chpasswd && usermod -aG wheel jboss && \
    chown -R jboss:0 /opt/jboss && \
    curl -L -o /tmp/jboss-eap-7.2.0.zip https://github.com/daggerok/jboss/releases/download/eap/jboss-eap-7.2.0.zip && \
    unzip /tmp/jboss-eap-7.2.0.zip -d /opt && \
    mv /opt/jboss-eap-7.2/* ${JBOSS_HOME} && \
    ${JBOSS_HOME}/bin/add-user.sh admin admin123 --silent && \
    echo 'JAVA_OPT="$JAVA_OPTS -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0"'  >> ${JBOSS_HOME}/bin/standalone.config && \
    yum clean all

EXPOSE 8080 9090 9990

USER jboss

CMD ["${JBOSS_HOME}/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]

