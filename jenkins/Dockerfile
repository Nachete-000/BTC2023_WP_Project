FROM jenkins/jenkins:lts-slim

USER root
RUN apt update && apt -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common && \
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt update && apt -y install docker-ce docker-ce-cli containerd.io && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i'' 's/^docker.*$/docker:x:998:jenkins/g' /etc/group && \
    usermod -a -G docker jenkins

ENV JAVA_ARGS="-Djava.net.preferIPv4Stack=true"
