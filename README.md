# plex-cloud-unlimited-storage
Setting up a cloud Ubuntu with Amazon Cloud Drive + Plex

##Setting up Plex.
- Download Plex
- dpkg -i `plex-file-version.deb`
- SSH with Tunnel to `localhost:32400`
- Access `http://localhost:32400` on local machine
- Link to Plex account, setup the rest of Plex later..

## Mount Amazon Cloud Drive + FUSE mounting
- First you need to register a ACD account... :)
- Install Python PIP `sudo apt-get install python3-pip`
- Install ACD CLI `sudo pip3 install --upgrade git+https://github.com/yadayada/acd_cli.git`
- Init ACD_CLI config: `acd_cli -v init`
- Test sync `acd_cli sync`
- Mount ACD to a folder `acd_cli mount ~/Amazon`


## Encrypting data the disk
Lets use EncFS for this.. its fast, reliable and safe.
- Install `sudo apt-get -y install encfs`
- Make a encrypted folder inside amazon: `mkdir ~/Amazon/encrypted`
- Make a uncrypted folder to read from: `mkdir ~/Media`
- Fire EncFS to setup the folders: `encfs /home/user/Amazon/encrypted/ /home/user/Media/` __FULL PATHS IS NEEDED HERE__


## UnionFS-FUSE to show local and ACD Cloud files in same folder.
more to come..

## Setup Plex
more to come..

## Setup services
more to come..
