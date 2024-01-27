FROM ubuntu AS build

# Configure prereqs
RUN apt-get update && apt-get install -yq \
    gnupg2 \
    libcanberra-gtk3-module \
    wget

# Fetch the apt key
RUN sh -c \
    'wget -q -O - \
    https://dl-ssl.google.com/linux/linux_signing_key.pub \
  | gpg --dearmor \
  > /etc/apt/trusted.gpg.d/google.gpg'

# Add the repo
RUN sh -c \
    'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
 >> /etc/apt/sources.list.d/google.list'

# Update the repos and install chrome
RUN apt-get update && apt-get install -yq \
    google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

FROM build AS drop-privileges
# Create user
ENV USER=chrome \
    UID=40915 \
    TEMPLATE=/chrome/Downloads
# Whoever owns /chrome/Downloads owns the instance

WORKDIR /chrome

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --no-create-home \
    --uid "$UID" \
    "$USER" \
 && adduser "$USER" audio \
 && adduser "$USER" video \
 && mkdir "$TEMPLATE" \
 && chown -R "$USER":"$USER" .

ADD https://raw.githubusercontent.com/Rexypoo/docker-entrypoint-helper/master/entrypoint-helper.sh /usr/local/bin/entrypoint-helper.sh
RUN chmod u+x /usr/local/bin/entrypoint-helper.sh
ENTRYPOINT ["entrypoint-helper.sh", "/usr/bin/google-chrome"]

# Build with 'docker build -t chrome .'
LABEL org.opencontainers.image.url="https://hub.docker.com/r/rexypoo/chrome" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/rexypoo/chrome" \
      org.opencontainers.image.source="https://github.com/Rexypoo/docker-chrome" \
      org.opencontainers.image.version="0.1a" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Chrome on Docker" \
      org.opencontainers.image.title="rexypoo/chrome" \
      org.label-schema.docker.cmd='mkdir -p "$HOME"/.chrome-settings && \
      docker run -d --rm \
      --name chrome \
      --net=host \
      -e DISPLAY \
      -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
      -v "$HOME"/Downloads:/chrome/Downloads \
      -v "$HOME"/.chrome-settings:/chrome/.config/google-chrome \
      --security-opt seccomp=unconfined \
      --device /dev/dri \
      --device /dev/snd \
      -v /dev/shm:/dev/shm \
      rexypoo/chrome' \
      org.label-schema.docker.cmd.devel="docker run -it --rm --entrypoint bash rexypoo/chrome" \
      org.label-schema.docker.cmd.debug="docker exec -it chrome bash"
