#!/usr/bin/env bash
set -e

echo "Fetching SSH keys"
su -c '
  set -e; \
  mkdir -p $HOME/.ssh; \
  curl -fsSL https://github.com/hizkifw.keys > $HOME/.ssh/authorized_keys; \
  ssh-keyscan github.com gitlab.com > $HOME/.ssh/known_hosts; \
  chmod 700 $HOME/.ssh; \
  chmod 600 $HOME/.ssh/{authorized_keys,known_hosts};' \
  nomad

# Copy the ssh folder if needed
if [ -z "$(ls -A /etc/ssh)" ]; then
  cp -a /etc/ssh.bak/* /etc/ssh
fi

# Check if host keys are available
if ! ls /etc/ssh/ssh_host_* 1> /dev/null 2>&1; then
  echo "Host keys not available, generating new ones"
  ssh-keygen -A
fi

# Ensure the workspace directory has the right permissions
chown nomad:nomad /home/nomad/workspace

stop() {
    echo "Shutting down sshd"
    pid=$(cat /var/run/sshd/sshd.pid)
    kill -SIGTERM "$pid"
    wait "$pid"
}

echo "Running $@"
if [ "$(basename $1)" == "sshd" ]; then
    trap stop SIGINT SIGTERM
    $@ &
    pid="$!"
    mkdir -p /var/run/sshd && echo "${pid}" > /var/run/sshd/sshd.pid
    wait "${pid}"
    exit $?
else
    exec "$@"
fi
