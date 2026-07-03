FROM archlinux:latest

# Use all cores for compilation
RUN echo "MAKEFLAGS=\"-j$(nproc)\"" >> /etc/makepkg.conf

# Update system and install official packages
RUN pacman -Syu --needed --noconfirm \
      base-devel git openssh sudo less inetutils whois \
      zsh starship fzf eza zoxide tmux btop man-db tldr \
      vim neovim \
      clang llvm rust libyaml \
      lazygit lazydocker \
      docker docker-buildx docker-compose \
      kitty-terminfo && \
    pacman -Scc --noconfirm

# Create a non-root user
RUN useradd -m -s /usr/bin/zsh omaterm-lite && \
    echo "omaterm-lite ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/omaterm-lite

USER omaterm-lite
WORKDIR /home/omaterm-lite
ENV SHELL=/usr/bin/zsh
ENV TERM=dumb

# Install yay
RUN git clone https://aur.archlinux.org/yay-bin.git /tmp/yay && \
    cd /tmp/yay && makepkg -si --noconfirm && \
    rm -rf /tmp/yay

# Copy local repo and run installer (lite flavor, server profile for non-interactive CI)
COPY --chown=omaterm-lite:omaterm-lite . /tmp/omaterm-lite
RUN OMATERM_INSTALLER_DIR=/tmp/omaterm-lite OMATERM_PROFILE=server OMATERM_FLAVOR=lite \
      bash /tmp/omaterm-lite/install.sh && \
    rm -rf /tmp/omaterm-lite

ENV PATH="/home/omaterm-lite/.local/bin:${PATH}"

ENTRYPOINT ["/home/omaterm-lite/.local/bin/omaterm-setup"]
