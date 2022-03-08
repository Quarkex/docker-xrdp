#!/bin/bash

if [ -f "/etc/user_source.csv" ]; then
# Create all users in builtin file
  echo Creating users:
  while IFS=',' read username uid gid passwordhash; do
    echo ' - '"$username"
    addgroup --gid $gid $username > /dev/null 2>&1 && \
    useradd -m -u $uid -s /bin/bash -g $username $username > /dev/null 2>&1
    echo -n "${username}:${passwordhash}" | tr -d '\n' | tr -d '\r' | /usr/sbin/chpasswd -e
    for g in audio adm cdrom dip plugdev lpadmin; do
      adduser $username "$g" > /dev/null 2>&1;
    done
  done < /etc/user_source.csv
else
# Add sample user
  # sample user uses uid 666 to reduce conflicts with user ids when mounting an existing home dir
  # run `openssl passwd -1 'newpassword'` to create a custom hash
  if [ ! $PASSWORDHASH ]; then
      export PASSWORDHASH='$1$mmPfWxGC$Y.ZHgORnD1ote/3v2OxnI0'
  fi

  addgroup --gid 666 operador && \
  useradd -m -u 666 -s /bin/bash -g operador operador
  echo "operador:$PASSWORDHASH" | /usr/sbin/chpasswd -e
  echo "operador ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-operador
  for g in audio sudo; do adduser operador "$g"; done
  unset PASSWORDHASH

fi

# Add the ssh config if needed

for file in authorized_keys; do
  if [ ! -f "/root/.ssh/$file" ] && [ -f "/ssh_user_orig/$file" ]; then
      cp "/ssh_user_orig/$file" "/root/.ssh/"
  fi
done

if [ ! -f "/etc/ssh/sshd_config" ];
  then
    cp /ssh_orig/sshd_config /etc/ssh
fi

if [ ! -f "/etc/ssh/ssh_config" ];
  then
    cp /ssh_orig/ssh_config /etc/ssh
fi

if [ ! -f "/etc/ssh/moduli" ];
  then
    cp /ssh_orig/moduli /etc/ssh
fi

# generate fresh rsa key if needed
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ];
  then
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

# generate fresh dsa key if needed
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ];
  then
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

# prepare run dir
mkdir -p /var/run/sshd

# generate xrdp key
if [ ! -f "/etc/xrdp/rsakeys.ini" ];
  then
    xrdp-keygen xrdp auto
fi

# generate certificate for tls connection
if [ ! -f "/etc/xrdp/cert.pem" ];
  then
    # delete eventual leftover private key
    rm -f /etc/xrdp/key.pem || true
    cd /etc/xrdp
    # TODO make data in certificate configurable?
    openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 365 \
    -subj "/C=US/ST=Some State/L=Some City/O=Some Org/OU=Some Unit/CN=Terminalserver"
    crudini --set /etc/xrdp/xrdp.ini Globals security_layer tls
    crudini --set /etc/xrdp/xrdp.ini Globals certificate /etc/xrdp/cert.pem
    crudini --set /etc/xrdp/xrdp.ini Globals key_file /etc/xrdp/key.pem
fi

# generate machine-id
uuidgen > /etc/machine-id

# set keyboard for all sh users
echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile

exec "$@"
