FROM nginx

RUN set -x \
    # Install qBittorrent-NoX
 && apt-get update \
 && apt-get install -y qbittorrent-nox dumb-init curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -x \
    # Add non-root user
 && useradd --system --uid 520 -m --shell /usr/sbin/nologin qbittorrent \
    # Create symbolic links to simplify mounting
 && mkdir -p /home/qbittorrent/.config/qBittorrent \
 && chown qbittorrent:qbittorrent /home/qbittorrent/.config/qBittorrent \
 && ln -s /home/qbittorrent/.config/qBittorrent /config \
    \
 && mkdir -p /home/qbittorrent/.local/share/data/qBittorrent \
 && chown qbittorrent:qbittorrent /home/qbittorrent/.local/share/data/qBittorrent \
 && ln -s /home/qbittorrent/.local/share/data/qBittorrent /torrents \
    \
 && mkdir /downloads \
 && chown qbittorrent:qbittorrent /downloads \
    # Check it works
 && su qbittorrent -s /bin/sh -c 'qbittorrent-nox -v'

RUN rm -rf /var/lib/apt/lists/*
# Install Supervisord
RUN apt-get update && apt-get install -y supervisor
# Custom Supervisord config
COPY supervisord-debian.conf /etc/supervisor/conf.d/supervisord.conf

RUN apt-get install -y zip unzip

COPY default.conf.template /etc/nginx/conf.d/default.conf.template
COPY nginx.conf /etc/nginx/nginx.conf

# Default configuration file.
COPY qBittorrent.conf /default/qBittorrent.conf

ENV HOME=/home/qbittorrent
CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf" && /usr/bin/supervisord
