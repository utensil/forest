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

# Install Samba and smbclient
RUN apt install -y samba smbclient

# Install rsync and uv (for rsyncy)
# so `uvx rsyncy can be used for showing progress for rsync
RUN apt install -y rsync
RUN ~/.local/bin/mise use -g uv

# Install openssh-server
RUN apt install -y openssh-server

# Create privilege separation directory for sshd
RUN mkdir -p /run/sshd

# Copy Samba config and scripts
COPY smb.conf /etc/samba/smb.conf
COPY start-samba.sh /start-samba.sh
COPY stop-samba.sh /stop-samba.sh
COPY test-samba.sh /test-samba.sh
COPY vera /vera
COPY vera-off /vera-off
RUN chmod +x /start-samba.sh /stop-samba.sh /test-samba.sh /vera /vera-off

# Copy SSH start/stop scripts
COPY start-ssh.sh /start-ssh.sh
COPY stop-ssh.sh /stop-ssh.sh
RUN chmod +x /start-ssh.sh /stop-ssh.sh

# Create shared directory
RUN mkdir -p /mnt/shared && chmod 770 /mnt/shared


# Print welcome message on container start
CMD echo "Container ready.\n\nSamba is NOT running by default. To set up and start Samba, run: /start-samba.sh\n\nSSH server is NOT running by default. To set up and start SSH, run: /start-ssh.sh\n" && bash
