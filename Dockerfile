FROM archlinux:base-devel

# Install stuff
RUN \
  sudo pacman -Syu --noconfirm \
  neofetch neovim tmux git docker docker-compose \
  curl wget jq ripgrep direnv bind \
  zsh upx p7zip zstd htop rsync rclone ffmpeg \
  rustup go python python-pip sqlite postgresql-libs \
  tealdeer openssh lsof highlight

# Create user with sudo privileges
RUN \
  set -ex; \
  useradd \
    --create-home \
    --uid 1000 \
    --shell /bin/zsh \
    --groups wheel \
    nomad; \
  chmod 700 /home/nomad; \
  usermod -aG wheel nomad; \
  echo "nomad ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;
USER nomad
WORKDIR /home/nomad

# Install yay
RUN \
  set -ex; \
  mkdir -p $HOME/workspace; \
  cd workspace; \
  git clone https://aur.archlinux.org/yay-bin.git; \
  cd yay-bin; \
  makepkg -si --noconfirm; \
  cd ..; \
  rm -rf yay-bin;

# Install yay packages
RUN yay -S --noconfirm pandoc-bin;

# Run setup script as user
RUN rustup install stable
RUN tldr --update

# Clone dotfiles
RUN \
  set -ex; \
  mkdir -p \
    $HOME/.config \
    $HOME/.local/app/stub; \
  cd $HOME/workspace; \
  git clone https://github.com/hizkifw/dotfiles.git; \
  cd dotfiles; \
  git remote set-url origin git@github.com:hizkifw/dotfiles.git; \
  ln -s $(pwd)/dot/tmux.conf $HOME/.tmux.conf; \
  ln -s $(pwd)/dot/zshrc     $HOME/.zshrc; \
  ln -s $(pwd)/dot/antigen   $HOME/.config/antigen; \
  ln -s $(pwd)/dot/nvim      $HOME/.config/nvim;

# Set up zsh
RUN zsh -lc '. ~/.zshrc'

# Install node
RUN \
  zsh -lc '. ~/.zshrc; \
    nvm install --lts; \
    nvm use --lts; \
    npm install --location=global npm yarn neovim;'

# Set up neovim
RUN \
  zsh -lc '. ~/.zshrc; \
    python3 -m pip install --user neovim; \
    nvim --headless -c ":PlugInstall" -c ":qa";'

# Set up coc.nvim
RUN \
  zsh -lc '. ~/.zshrc; \
    nvim --headless &; \
    echo "Waiting for coc.nvim to start installing packages"; \
    until [ \
      $(ps aux | grep -v grep | grep "npm install" | wc -l) \
      -gt 0 \
    ]; do sleep 0.1; done; \
    echo "Waiting for coc.nvim to finish installing packages"; \
    until [ \
      $(ps aux | grep -v grep | grep "npm install" | wc -l) \
      -eq 0 \
    ]; do sleep 0.1; done; \
    echo "Packages should be installed, killing nvim"; \
    kill %1;'

# Install go language tools
RUN \
  zsh -lc '. ~/.zshrc; \
    nvim --headless -c ":GoUpdateBinaries" -c ":qa";'

# Install rust-analyzer
RUN \
  set -ex; \
  outdir=~/.config/coc/extensions/coc-rust-analyzer-data; \
  mkdir -p $outdir; \
  curl -fsSL https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz \
    | gunzip -c > $outdir/rust-analyzer; \
  chmod +x $outdir/rust-analyzer;

# Add my public keys
RUN \
  set -ex; \
  mkdir -p $HOME/.ssh; \
  curl https://github.com/hizkifw.keys > $HOME/.ssh/authorized_keys; \
  chmod 700 $HOME/.ssh; \
  chmod 600 $HOME/.ssh/authorized_keys;

VOLUME /home/nomad/workspace
VOLUME /etc/ssh

USER root
ENTRYPOINT ["ssh-keygen", "-A"]
CMD ["/usr/sbin/sshd", "-D"]
