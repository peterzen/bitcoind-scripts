#/bin/bash

BITCOIND_USER=bitcoin
TOR_GROUP=debian-tor
DATADIR_SNAPSHOT_REPO=gs://<YOUR GS URL>

BITCOIN_HOME=/home/$BITCOIND_USER
BITCOIN_DATA_DIR=$BITCOIN_HOME/.bitcoin
BITCOIN_CONF=$BITCOIN_DATA_DIR/bitcoin.conf

sudo useradd -U -m $BITCOIND_USER


# fix default ubuntu locale setup
echo 'LANGUAGE="en_US.UTF-8"' | sudo tee -a /etc/default/locale
echo 'LC_ALL="en_US.UTF-8"' | sudo tee -a /etc/default/locale

BITCOIN_NETWORK=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/BITCOIN_NETWORK" -H "Metadata-Flavor: Google")

RPC_USER=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/RPC_USER" -H "Metadata-Flavor: Google")
RPC_PASSWORD=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/RPC_PASSWORD" -H "Metadata-Flavor: Google")

echo 
echo * Bitcoin network: $BITCOIN_NETWORK
echo

# install bitcoind

sudo apt-get update && sudo apt-get -y upgrade

sudo apt-get -y install build-essential \
  libtool autotools-dev autoconf \
  libssl-dev \
  libboost-all-dev \
  pwgen \
  screen ca-certificates openssl ntp ntpdate

sudo add-apt-repository -y ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get -y install bitcoind


# install tor

sudo apt-get -y install automake git pkg-config libssl-dev libtool

echo 'deb http://deb.torproject.org/torproject.org xenial main' | sudo tee /etc/apt/sources.list.d/torproject.list

gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -


sudo apt-get update

sudo apt-get -y install tor deb.torproject.org-keyring

# configure tor
cat  <<__EOF | sudo tee -a /etc/tor/torrc
ControlPort 9051
CookieAuthentication 1
CookieAuthFileGroupReadable 1
__EOF

sudo usermod -a -G $TOR_GROUP $BITCOIND_USER

sudo service tor restart



# configure bitcoind

sudo mkdir $BITCOIN_DATA_DIR


if [ "$BITCOIN_NETWORK" = "testnet" ]; then
cat << __EOF_TESTNET_CONF | sudo tee $BITCOIN_CONF 
testnet=1
listen=1
disablewallet=0
daemon=1
#onlynet=onion
bind=0.0.0.0:18333
onion=127.0.0.1:9050
server=1
rpcuser=bitcoin_rpc
rpcpassword=$RPC_PASSWORD
rpcbind=0.0.0.0:18332
rpcallowip=0.0.0.0/0
__EOF_TESTNET_CONF

else
cat << __EOF_MAINNET_CONF | sudo tee $BITCOIN_CONF
testnet=0
listen=1
disablewallet=0
daemon=1
#onlynet=onion
bind=0.0.0.0:8333
onion=127.0.0.1:9050
server=1
rpcuser=$RPC_USER
rpcpassword=$RPC_PASSWORD
rpcbind=0.0.0.0:8332
rpcallowip=0.0.0.0/0
__EOF_MAINNET_CONF
	
	
fi;


sudo gsutil -m  rsync -r  gs://bitcoin-data.prioritylane.com/$BITCOIN_NETWORK /home/bitcoin/.bitcoin


sudo mkdir /usr/lib/systemd/system

sudo tee  /usr/lib/systemd/system/bitcoind.service << __EOF_SERVICE
[Unit]
Description=Bitcoin's distributed currency daemon
After=network.target

[Service]
User=bitcoin
Group=bitcoin

Type=simple
PIDFile=/var/lib/bitcoind.pid
ExecStart=/usr/bin/bitcoind  -daemon

RemainAfterExit=yes
Restart=always
PrivateTmp=true
TimeoutStopSec=360s
TimeoutStartSec=360s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
__EOF_SERVICE

sudo chown -R $BITCOIND_USER $BITCOIN_HOME

sudo systemctl daemon-reload
sudo systemctl enable bitcoind

sudo systemctl start bitcoind



