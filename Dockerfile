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

# Install omadots
RUN curl -fsSL https://raw.githubusercontent.com/hattapauzi/omadots/master/install.sh | bash

# Copy configs and bins
COPY --chown=omaterm-lite:omaterm-lite config/ /home/omaterm-lite/.config/
COPY --chown=omaterm-lite:omaterm-lite bin/ /home/omaterm-lite/.local/bin/
RUN chmod +x /home/omaterm-lite/.local/bin/*

ENV PATH="/home/omaterm-lite/.local/bin:${PATH}"

ENTRYPOINT ["/home/omaterm-lite/.local/bin/omaterm-setup"]
