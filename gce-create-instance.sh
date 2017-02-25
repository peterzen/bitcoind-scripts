
PROJECT_ID="prioritylane-001"
INSTANCE_NAME="bitcoin-mainnet"
ZONE="europe-west1-b"
SERVICE_ACCOUNT=bitcoind-mainnet@prioritylane-001.iam.gserviceaccount.com
BITCOIN_NETWORK=mainnet

RPC_USER=bitcoin_rpc
RPC_PASSWORD=$(openssl rand -base64 32)
#export DATA_DISK="$INSTANCE_NAME-data"


#gcloud compute --project $PROJECT_ID disks create $DATA_DISK \
#  --size "250" \
#  --zone $ZONE \
#  --type "pd-standard" \
#  --source-snapshot "bitcoin-data-snapshot-4"

gcloud compute --project $PROJECT_ID instances create $INSTANCE_NAME --zone $ZONE \
  --machine-type "n1-standard-1" \
  --network "default" \
  --maintenance-policy "MIGRATE"  \
  --image "ubuntu-1610-yakkety-v20170222" \
  --image-project "ubuntu-os-cloud" \
  --boot-disk-size "250" \
  --boot-disk-type "pd-standard" \
  --boot-disk-device-name $INSTANCE_NAME \
  --metadata "BITCOIN_NETWORK=$BITCOIN_NETWORK,RPC_USER=$RPC_USER,RPC_PASSWORD=$RPC_PASSWORD" \
  --tags "bitcoin-$BITCOIN_NETWORK" 
#--service-account $SERVICE_ACCOUNT \
#  --metadata-from-file startup-script=gce-bitcoind-install.sh 
#  --disk "name=$DATA_DISK,device-name=bitcoind-data,mode=rw,boot=no,auto-delete=yes"



# gcloud compute --project $PROJECT_ID instances attach-disk $INSTANCE_NAME --disk $DATA_DISK --device-name "bitcoind-data"


# run these on the newly created instance
#echo "/dev/disk/by-id/google-bitcoind-data-part1    /mnt    ext4    defaults    0 0" | sudo tee -a /etc/fstab
#sudo mount /mnt

