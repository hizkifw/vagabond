#!/usr/bin/env bash
set -e

echo "Fetching SSH keys"
su -c '
  set -e;
  mkdir -p $HOME/.ssh;
  ssh-keyscan github.com gitlab.com > $HOME/.ssh/known_hosts;
  curl -fsSL https://github.com/hizkifw.keys > $HOME/.ssh/authorized_keys;
  curl -fsSL https://github.com/hizkifw.gpg \
    | gpg --import 2>&1 | grep " key " | cut -d" " -f3 | tr -d ":" \
    | xargs -I{} gpg -k {} | grep -oE "[0-9A-F]{40}" | xargs -I{} echo {}:6: \
    | gpg --import-ownertrust;
  chmod 700 $HOME/.ssh;
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

# Update the Docker group ID if needed
if [ -f /var/run/docker.sock ]; then
  outside_docker_gid=$(stat -c '%g' /var/run/docker.sock)
  current_docker_gid=$(getent group docker | cut -d: -f3)
  if [ "$outside_docker_gid" != "$current_docker_gid" ]; then
    groupadd -g $outside_docker_gid hostdocker
    usermod -aG hostdocker nomad
  fi
fi

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
