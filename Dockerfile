FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit packages for Wine
RUN dpkg --add-architecture i386

# Bullseye has moved to Debian's archive mirrors.
# Disable the archive metadata expiry check.
RUN sed -i \
    -e 's|deb.debian.org/debian-security|archive.debian.org/debian-security|g' \
    -e 's|deb.debian.org/debian|archive.debian.org/debian|g' \
    /etc/apt/sources.list \
    && sed -i '/stretch-updates/d' /etc/apt/sources.list \
    && apt-get update -o Acquire::Check-Valid-Until=false \
    && apt-get install -y --no-install-recommends \
        xrdp \
        xfce4 \
        xfce4-goodies \
        xorg \
        dbus-x11 \
        sudo \
        curl \
        wget \
        nano \
        net-tools \
        policykit-1 \
        pulseaudio \
        pulseaudio-utils \
        wine \
        wine32 \
        firefox-esr \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set root password
RUN echo "root:root" | chpasswd

# Allow Xorg to run for XRDP
RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config \
    || echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

# XFCE session
RUN echo "startxfce4" > /root/.xsession \
    && chmod 700 /root/.xsession

# Generate machine-id for DBus
RUN mkdir -p /var/run/dbus \
    && dbus-uuidgen > /var/lib/dbus/machine-id

# Configure XRDP
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini \
    && sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini \
    && echo "exec startxfce4" > /etc/xrdp/startwm.sh \
    && chmod +x /etc/xrdp/startwm.sh

# Add xrdp to SSL certificate group
RUN adduser xrdp ssl-cert

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
