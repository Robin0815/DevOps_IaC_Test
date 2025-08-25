FROM saltstack/salt:latest

# Install additional packages for web UI support
RUN apt-get update && apt-get install -y \
    python3-cherrypy3 \
    python3-ws4py \
    && rm -rf /var/lib/apt/lists/*

# Create saltapi user for authentication
RUN useradd -m -s /bin/bash saltapi && \
    echo "saltapi:saltapi" | chpasswd

# Copy configuration files
COPY salt-master-config/master /etc/salt/master

# Create startup script
RUN echo '#!/bin/bash\n\
salt-master -d\n\
sleep 5\n\
salt-api -d\n\
tail -f /var/log/salt/master /var/log/salt/api' > /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]