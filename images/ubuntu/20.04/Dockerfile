FROM ubuntu:20.04 as builder
MAINTAINER Daniel Guerra

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev libfuse-dev libpulse-dev libtool \
    xserver-xorg-dev wget ssl-cert \
    libmp3lame0 libmp3lame-dev libfdk-aac-dev libjpeg-dev libopus-dev \
    libturbojpeg0-dev"
RUN apt update && apt -y full-upgrade && apt install -y sudo apt-utils software-properties-common $BUILD_DEPS


# Build xrdp

WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-13.99.1
RUN dpkg-buildpackage -rfakeroot -uc -b
WORKDIR /tmp
RUN git clone --branch v0.9 --recursive https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp
RUN ./bootstrap
RUN ./configure \
  --enable-fdkaac \
  --enable-jpeg \
  --enable-mp3lame \
  --enable-opus \
  --enable-pixman \
  --enable-rdpsndaudin \
  --enable-tjpeg \
  --enable-vsock \
  --enable-fuse

RUN make
RUN make install
WORKDIR /tmp
RUN  apt -yy install libpulse-dev
RUN git clone --recursive https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/pulseaudio-module-xrdp
RUN ./bootstrap && ./configure PULSE_DIR=/tmp/pulseaudio-13.99.1
RUN make
RUN mkdir -p /tmp/so
RUN cp src/.libs/*.so /tmp/so

FROM ubuntu:20.04
ARG ADDITIONAL_PACKAGES=""
ENV ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES}
ENV DEBIAN_FRONTEND noninteractive
RUN echo "Adding repositories" \
  && apt-get update \
  && apt install curl -y \
  && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"| tee /etc/apt/sources.list.d/brave-browser-release.list
COPY packages /tmp/packages/
RUN echo "Installing packages" \
  && echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections \
  && apt update && apt -y full-upgrade && apt install -y \
  linux-tools-generic \
  sshfs \
  apt-transport-https \
  libgconf-2-4 \
  net-tools \
  winbind \
  xrdp \
  xorgxrdp \
  ca-certificates \
  crudini \
  htop \
  less \
  libmp3lame0 \
  locales \
  openssh-server \
  ssl-cert \
  sudo \
  supervisor \
  ttf-mscorefonts-installer \
  uuid-runtime \
  wget \
  xauth \
  xautolock \
  xterm \
  ubuntu-mate-core \
  xprintidle \
  language-pack-es-base \
  language-pack-es \
  gnome-user-docs-es \
  language-pack-gnome-es \
  wspanish \
  $ADDITIONAL_PACKAGES \
  && \
  apt remove -y light-locker && \
  apt install -y /tmp/packages/python-twodict_1.2-1_all.deb && \
  apt install -y /tmp/packages/youtube-dlg_0.4-1~webupd8~disco0_all.deb && \
  apt remove --purge -y update-manager mate-screensaver mate-screensaver-common && \
  apt autoremove --purge -y && \
  rm -rf /tmp/packages && \
  rm -rf /var/cache/apt /var/lib/apt/lists && \
  adduser xrdp ssl-cert  && \
  mkdir -p /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-sink.so /var/lib/xrdp-pulseaudio-installer
ADD bin /usr/bin
ADD etc /etc
ADD autostart /etc/xdg/autostart

WORKDIR /tmp

COPY bin /usr/bin
COPY etc /etc
COPY autostart /etc/xdg/autostart

ENV DEBCONF_NONINTERACTIVE_SEEN=true
# Configure
RUN mkdir /var/run/dbus && \
  cp /etc/X11/xrdp/xorg.conf /etc/X11 && \
  sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config && \
  sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini && \
  locale-gen es_ES.UTF-8 && \
  update-locale LANG=es_ES.UTF-8 LANGUAGE=es_ES:es && \
  sed -i 's/^XKBLAYOUT="us"$/XKBLAYOUT="es"/g' /etc/default/keyboard && \
  ln -fs /usr/share/zoneinfo/Atlantic/Canary /etc/localtime && \
  dpkg-reconfigure --frontend noninteractive tzdata && \
  echo "pulseaudio -D" > /etc/skel/.Xsession && \
  echo "mate-session" >> /etc/skel/.Xsession && \
  echo "mate-session" > /etc/skel/.Xclients && \
  echo "" > /etc/skel/.Xclients && \
  echo "XDG_DATA_DIRS=/usr/share/mate:/usr/share/mate:/usr/local/share" > /etc/environment && \
  echo "XDG_DATA_DIRS=${XDG_DATA_DIRS}:/usr/share:/var/lib/snapd/desktop" > /etc/environment && \
  echo "export XDG_SESSION_DESKTOP=mate" > /etc/skel/.Xclients && \
  echo "export XDG_DATA_DIRS=${XDG_DATA_DIRS}" > /etc/skel/.Xclients && \
  echo "export XDG_CONFIG_DIRS=/etc/xdg/xdg-mate:/etc/xdg" > /etc/skel/.Xclients && \
  cp -r /etc/ssh /ssh_orig && \
  rm -rf /etc/ssh/* && \
  rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem

ENV LANG=es_ES.UTF-8
ENV LANGUAGE=es_ES:es
ENV LC_ALL=es_ES.UTF-8

RUN sed -i '5s#$#\nif [[ -f /etc/bash_aliases ]]; then\n  . /etc/bash_aliases\nfi\nif [[ -d /etc/bash_aliases.d ]]; then\n  if ls /etc/bash_aliases.d/*.sh &>/dev/null; then\n    for alias_source_file in /etc/bash_aliases.d/*.sh; do\n      . "$alias_source_file"\n    done\n  fi\nfi\n#' /etc/bash.bashrc
RUN echo '\
user-db:user\n\
system-db:local' > /etc/dconf/profile/user \
  && mkdir -p /etc/dconf/db/local.d \
  && echo '\
[org/mate/desktop/session]\n\
logout-prompt=false' > /etc/dconf/db/local.d/01-mate-session \
  && echo '\
[org/gnome/desktop/lockdown]\n\
disable-lock-screen=true\n\
user-administration-disabled=true\n\
disable-user-switching=true' > /etc/dconf/db/local.d/01-gnome-lockdown \
  && echo '\
[org/mate/desktop/lockdown]\n\
disable-lock-screen=true\n\
disable-user-switching=true' > /etc/dconf/db/local.d/01-mate-lockdown \
  && echo '\
[org/mate/power-manager]\n\
lock-blank-screen=false\n\
lock-hibernate=false\n\
lock-suspend=false\n\
lock-use-screensaver=false' > /etc/dconf/db/local.d/01-mate-power-manager \
  && echo '\
[apps/indicator-session]\n\
user-show-menu=false\n\
suppress-logot-restart-shutdown=true\n\
suppress-restart-menuitem=true\n\
suppress-shutdown-menuitem=true' > /etc/dconf/db/local.d/01-indicator-session \
  && dconf update

# Docker config
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
