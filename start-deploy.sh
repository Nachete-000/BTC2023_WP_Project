#!/bin/bash

# Function getgrafanacredentials
# Check if grafana secret exists

function getgrafanacredentials {
    
    if [ -e ./grafana/grafana_admin_pwd ]; then
        echo "Grafana admin credentials exists"
        echo 
        
    else
        # Read Password
        echo "Enter Grafana admin Password:"
        echo
        read -s password
        # Store Password in docker secret Command
        echo $password > ./grafana/grafana_admin_pwd
        unset $password
    fi
}

# Function DeployServices
function deployservices {
    docker compose -f docker-compose-svc.yml up -d

    CONTAINER_NAME_CHECK="Jenkins-svc"
    while [ "${CHECK}" != "running" ]
    do
    CHECK=$(docker container inspect --format '{{.State.Status}}' ${CONTAINER_NAME_CHECK} 2>&1)
        sleep 5
    done

}

# Function jenkinsinit
# Check if Jenkins is already setup
function jenkinsinit {
    docker exec -it Jenkins-svc sh -c 'ls /var/jenkins_home/secrets/initialAdminPassword ; exit $?' > /dev/null
    if [ "$?" = 0 ]; then
        echo
        echo "Wordpress use FQDN to grant access to url"
        echo "Configure your DNS to map wp.local stgwp.local and devwp.local to your docker host IP address with a A reg"
        echo "Or edit your hosts file with in host to map wp.localstgwp.local and devwp.local to your docker host IP address"
        echo "Sample:"
        echo "  sudo nano /etc/hosts"
        echo " add line"
        echo " 192.168.1.30 wp.local stgwp.local devwp.local"
        echo 
        echo "If you are going to use a remote computer to access with a web browser, modify too the hosts file"
        echo "If you use windows find the file under %windir%\system32\drivers\etc use Administrator UAC rights to modify"
        echo
        echo "Enter with a web browser http://<ip_address>:8080 to setup Jenkins"
        echo "Use this password to setup Jenkins:"
        echo
        echo -n -e "\033[0;92m                  "
        docker exec Jenkins-svc cat /var/jenkins_home/secrets/initialAdminPassword
        echo
        echo -n -e "\033[0;39m"
        echo "Configure Jenkins:"
        echo " - Install sugessted plugins"
        echo " - Create first user admin and set password"
        echo " - Set the url http://<ip_address>:8080"
        echo " - Start using Jenkins"
        echo " - Create a Job: Multibranch Pipeline"
        echo " - Source: Git"
        echo " - For public: Enter http path"
        echo " - For private: enter ssh path and add credentias with git private key"
        echo "     - user: git user"
        echo "     - privatekey: our private key from git"
        echo "     - passphrase: passphrase for private key"
        echo " - Behaviours, check is enabled: Discover branches"
        echo " - Property strategy: All branches get the same properties"
        echo " - Build Configuration: Mode by Jenkinsfile"
        echo "      - Script Path: Jenkinsfile"
        echo " - Scan Multibranch Pipeline Triggers:"
        echo "      - Select: Periodically if not otherwise run"
        echo "      - Interval: Establecer el tiempo, para un entorno de prueba se puede poner un valor bajo de 5 min para que los cambios sucedan nada mas hacer el commit. También puede lanzarse manualmente."
        echo " - Orphaned Item Strategy:"
        echo "      - Seleccionar: Discard old items"
        echo " - Health metrics: don't change"
        echo " - Pipeline Libraries: don't change"
        echo "     - go to Jenkins admin -> security global configuration, and select one:"
        echo "           - Accept first connection"
        echo "           - Accept manually"
        echo "           - use know_hosts"
        echo "                - for know_hosts:"
        echo "                - docker exec -it Jenkins-svc /bin/bash"
        echo "                - $ mkdir $JENKINS_HOME/.ssh"
        echo "                - $ touch $JENKINS_HOME/.ssh/known_hosts"
        echo "                - $ ssh-keyscan -t rsa github.com >> $JENKINS_HOME/.ssh/known_hosts"
        echo " - Configure credentials for users, configure with Jenkins ID:"
        echo "     - User / Password for WordPress database / MySQL: WPDB"
        echo "     - User / Password for WordPress portal          : WPPORTAL"
        echo "     - User / Password for root MySQL                : MYSQLADMIN"
        echo "     - User / Password for Prometheus MySQL exporter : MYSQLMONUSR"
        echo "      If users not exists, pipeline will not work"
        echo " - Jenkins script approval must be lauched and approved for this scripts"
        echo "     - Launch Jenkins, pipeline show an error, go to console output, clic on approval and approve script under control panel, admin Jenkins, ScriptApproval"
        echo "     - Repeat this step for each script"
        echo " - Configure Grafana"
        echo " - Go to http://<ip_address>:3000"
        echo " - Access with default credentials"
        echo "     - User: admin"
        echo "     - Password: configured with this cript"
    else
        echo "Enter with a web browser http://<ip_address>:8080 to manage Jenkins"
        echo "Enter with a web browser http://<ip_address>:3000 to manage Grafana"
    fi

    echo "Enter with a web browser http://<ip_address>:9090 to manage Prometheus"
    echo "Dev site: http://devwp.local:5080"
    echo "Stg site: http://stgwp.local:4080"
    echo "Prd site: http://wp.local:80"
}

# Initizalize docker swarm to enable secrets
    case "$(docker info --format '{{.Swarm.LocalNodeState}}')" in
        inactive)
            echo "Node is not in a swarm cluster"
            docker swarm init

            getgrafanacredentials
            
            deployservices
            
            jenkinsinit;;
            
        pending)
            echo "ERROR: Node is not in a swarm cluster"

            exit 1;;
        active)
            echo "Node is in a swarm cluster"

            getgrafanacredentials

            deployservices

            jenkinsinit

            exit 0;;
        locked)
            echo "ERROR: Node is in a locked swarm cluster"

            exit 1;;
        error)
            echo "ERROR: Node is in an error state"

            exit 1;;
        *)
            echo "Unknown state $(docker info --format '{{.Swarm.LocalNodeState}}')"

            exit 1;;
    esac