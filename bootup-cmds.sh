# a list of commands to be run on boot of a new os image

git clone https://github.com/FiachraBarry99/civil-defence-project && \
cd civil-defence-project && \
chmod +x *.sh && \
cp config.example.sh config.sh && \
nano config.sh

sudo ./pin-interfaces.sh && \
sudo ./install.sh