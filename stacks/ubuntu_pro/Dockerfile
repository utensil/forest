# AGENT-NOTE: Secure Ubuntu Pro Dockerfile for Samba + VeraCrypt
# Base image
FROM ubuntu:22.04

# Set noninteractive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools (bt-ubuntu)
RUN apt update
RUN apt install -y build-essential curl file git sudo neovim

# Install mise (bt-ubuntu)
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:$PATH"
RUN ~/.local/bin/mise trust && ~/.local/bin/mise use -g just
RUN echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Install VeraCrypt (prep-vera)
RUN apt install -y wget exfat-fuse exfatprogs && \
    VERSION=$(grep VERSION_ID /etc/os-release | sed -e 's/[^0-9.]//g') && \
    DEB_URL="https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Ubuntu-$VERSION-amd64.deb" && \
    TMP_DEB="/tmp/veracrypt-$VERSION.deb" && \
    wget -O "$TMP_DEB" "$DEB_URL" && \
    apt install -y "$TMP_DEB" && \
    rm -f "$TMP_DEB" && \
    which mount.exfat || ln -s /usr/sbin/mount.exfat-fuse /usr/sbin/mount.exfat && \
    grep exfat /etc/filesystems || echo exfat >> /etc/filesystems

# Install Samba
RUN apt install -y samba

# Copy Samba config and scripts
COPY smb.conf /etc/samba/smb.conf
COPY start-samba.sh /start-samba.sh
COPY stop-samba.sh /stop-samba.sh
RUN chmod +x /start-samba.sh /stop-samba.sh

# Create shared directory
RUN mkdir -p /mnt/shared && chmod 770 /mnt/shared

# Expose only port 445 for modern SMB
EXPOSE 445/tcp

# Print welcome message on container start
CMD echo "Container ready. Samba is NOT running by default. To set up and start Samba, run: /start-samba.sh" && bash
