FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture for wine32
RUN dpkg --add-architecture i386

# Replace all Debian mirrors with the Bullseye archive.
# Remove security/updates entries that can cause 404s.
RUN printf '%s\n' \
    'deb [check-valid-until=no] http://archive.debian.org/debian bullseye main contrib non-free' \
    'deb [check-valid-until=no] http://archive.debian.org/debian bullseye-updates main contrib non-free' \
    > /etc/apt/sources.list \
    && rm -f /etc/apt/sources.list.d/* \
    && apt-get -o Acquire::Check-Valid-Until=false update \
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

# Root password
RUN echo "root:root" | chpasswd

# Xorg configuration
RUN if [ -f /etc/X11/Xwrapper.config ]; then \
        sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config; \
    else \
        mkdir -p /etc/X11 && \
        printf 'allowed_users=anybody\n' > /etc/X11/Xwrapper.config; \
    fi

# XFCE session
RUN printf '%s\n' '#!/bin/sh' 'startxfce4' > /root/.xsession \
    && chmod 700 /root/.xsession

# DBus
RUN mkdir -p /var/run/dbus \
    && dbus-uuidgen > /var/lib/dbus/machine-id

# XRDP configuration
RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini \
    && sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini \
    && printf '%s\n' '#!/bin/sh' 'unset DBUS_SESSION_BUS_ADDRESS' 'unset XDG_RUNTIME_DIR' 'startxfce4' \
       > /etc/xrdp/startwm.sh \
    && chmod +x /etc/xrdp/startwm.sh

# SSL certificate permissions
RUN adduser xrdp ssl-cert

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
