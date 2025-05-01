#cloud-config
users:
  - name: ${vm_admin_username}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${admin_ssh_public_key}

package_update: true
package_upgrade: true
packages:
  - openjdk-11-jdk
  - maven
  - git
  - wget

write_files:
  - path: /etc/systemd/system/tomcat.service
    permissions: '0644'
    content: |
      ${tomcat_unit_file}

runcmd:
  - cd /opt
  - wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.96/bin/apache-tomcat-8.5.96.tar.gz
  - tar -xzf apache-tomcat-8.5.96.tar.gz
  - mv apache-tomcat-8.5.96 tomcat8
  - chmod +x /opt/tomcat8/bin/*.sh
  - rm apache-tomcat-8.5.96.tar.gz

  - git clone https://github.com/PavloSuprun/todo-app /tmp/todo-app
  - sed -i 's|private static final String JDBC_URL =.*;|private static final String JDBC_URL = "${sql_connection_string}";|' /tmp/todo-app/src/main/java/com/example/util/DatabaseUtil.java
  - cd /tmp/todo-app
  - mvn clean package
  - cp /tmp/todo-app/target/todo-app.war /opt/tomcat8/webapps/

  - mkdir -p /opt/tomcat8/certs
  - sh -c "echo \"${ssl_certificate_pfx_base64}\" | base64 -d > /opt/tomcat8/certs/certificate.pfx"

  - sed -i '/<\/Service>/i \
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol" maxThreads="200" SSLEnabled="true" scheme="https" secure="true">\
      <SSLHostConfig>\
        <Certificate certificateKeystoreFile="/opt/tomcat8/certs/certificate.pfx" certificateKeystorePassword="${ssl_certificate_password}" />\
      </SSLHostConfig>\
    </Connector>' /opt/tomcat8/conf/server.xml

  - systemctl daemon-reload
  - systemctl enable tomcat.service
  - systemctl start tomcat.service

  - curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  - curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list
  - apt update
  - ACCEPT_EULA=Y apt install -y msodbcsql18 mssql-tools18
  - echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/profile.d/mssql-path.sh
  - source /etc/profile.d/mssql-path.sh
  - /opt/mssql-tools18/bin/sqlcmd -S ${sql_server_host}.database.windows.net -U ${sql_admin_username} -P ${sql_admin_password} -d ${sql_database_name} -i /tmp/todo-app/schema.sql
