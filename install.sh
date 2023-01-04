# UC client installation script

OLD_DIRECTORY=$(pwd)

# CD into a teporary folder
cd /tmp

# clone the repository

git clone https://github.com/kybeg/uc-client.git

# copy the uc script to /usr/local/bin

if cp uc-client/uc /usr/local/bin/uc; then

# set execution permissions
chmod +x /usr/local/bin/uc

# remove the repo

rm -r uc-client

# go back to original folder

cd $OLD_DIRECTORY

echo -e "\nuc client installed"

else

echo -e "\nSomething went wrong with the installation"

fi