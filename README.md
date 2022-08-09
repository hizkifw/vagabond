# vagabond

My personal development environment, containerized

```
# ~/.ssh/config

Host nomad
  User nomad
  HostName localhost
  Port 2222
  ForwardAgent yes
  RemoteForward /home/nomad/.gnupg/S.gpg-agent       /run/user/1000/gnupg/S.gpg-agent
  RemoteForward /home/nomad/.gnupg/S.gpg-agent.extra /run/user/1000/gnupg/S.gpg-agent.extra
```
