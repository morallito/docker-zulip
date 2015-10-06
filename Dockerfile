FROM ubuntu:trusty

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_DIR="/home/zulip" ZULIP_VERSION="1.3.6" DATA_DIR="/data" \
    DB_HOST="localhost" DB_PORT="5432" DB_USER="zulip" DB_PASSWORD="zulip" \
    RABBIT_HOST="localhost" \
    ZULIP_USER_FULLNAME="Zulip Docker" ZULIP_USER_EMAIL="" ZULIP_USER_PASSWORD="foobar" \
    ZULIP_SAVE_SETTINGS_PY="" ZULIP_USE_EXTERNAL_SETTINGS="false" \
    ZULIP_SETTINGS_EXTERNAL_HOST="localhost" \
    ZULIP_SECRETS_email_password=""

ADD entrypoint.sh /entrypoint.sh
ADD includes/zulip-puppet /root/zulip-puppet
RUN apt-get -qq update -q && \
    apt-get -qq dist-upgrade -y && \
    apt-get -qq install -y puppet git wget python-dev python-six python-pbs && \
    wget -q -O /root/zulip-ppa.asc https://zulip.com/dist/keys/zulip-ppa.asc && \
    apt-key add /root/zulip-ppa.asc && \
    echo "deb http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" > /etc/apt/sources.list.d/zulip.list && \
    echo "deb-src http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" >> /etc/apt/sources.list.d/zulip.list && \
    apt-get -qq update && \
    apt-get -qq dist-upgrade -y && \
    mkdir -p "/root/zulip" "/etc/zulip" "$DATA_DIR" && \
    wget -q "https://www.zulip.com/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" -P "/tmp" && \
    tar xfz "/tmp/zulip-server-$ZULIP_VERSION.tar.gz" -C "/root/zulip" --remove-files --strip-components=1 && \
    echo "[machine]\npuppet_classes = zulip::voyager\ndeploy_type = voyager" > /etc/zulip/zulip.conf && \
    rm -rf /root/zulip/puppet/zulip_internal /root/zulip/puppet/zulip && \
    mv -f /root/zulip-puppet /root/zulip/puppet/zulip && \
    /root/zulip/scripts/zulip-puppet-apply -f || : && \
    cp -a /root/zulip/zproject/local_settings_template.py /etc/zulip/settings.py && \
    ln -nsf /etc/zulip/settings.py /root/zulip/zproject/local_settings.py && \
    ZULIP_DEPLOY_PATH=$(/root/zulip/zulip_tools.py make_deploy_path) && \
    mv /root/zulip "$ZULIP_DEPLOY_PATH" && \
    ln -nsf "$ZULIP_DIR/deployments/next" /root/zulip && \
    ln -nsf "$ZULIP_DEPLOY_PATH" "$ZULIP_DIR/deployments/next" && \
    ln -nsf "$ZULIP_DEPLOY_PATH" "$ZULIP_DIR/deployments/current" && \
    ln -nsf /etc/zulip/settings.py "$ZULIP_DEPLOY_PATH/zproject/local_settings.py" && \
    cp -rfT "$ZULIP_DEPLOY_PATH/prod-static/serve" "$ZULIP_DIR/prod-static" && \
    chown -R zulip:zulip /home/zulip /var/log/zulip /etc/zulip/settings.py && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["$DATA_DIR"]

ENTRYPOINT ["/entrypoint.sh"]
