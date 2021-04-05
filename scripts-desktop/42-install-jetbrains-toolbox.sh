#!/usr/bin/env bash

source /tmp/common.sh

[[ "$(id -u)" != "0" ]] && exec sudo "$0" "$@"
echo -e " \e[94mInstalling Jetbrains Toolbox\e[39m"
echo ""

function getLatestUrl() {
    USER_AGENT=('User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36')
    URL=$(
        retry curl 'https://data.services.jetbrains.com//products/releases?code=TBA&latest=true&type=release' \
            -H 'Origin: https://www.jetbrains.com' \
            -H 'Accept-Encoding: gzip, deflate, br' \
            -H 'Accept-Language: en-US,en;q=0.8' \
            -H "${USER_AGENT[@]}" \
            -H 'Accept: application/json, text/javascript, */*; q=0.01' \
            -H 'Referer: https://www.jetbrains.com/toolbox/download/' \
            -H 'Connection: keep-alive' \
            -H 'DNT: 1' \
            --compressed | grep -Po '"linux":.*?[^\\]",' | awk -F ':' '{print $3,":"$4}'| sed 's/[", ]//g'
    )
    echo $URL
}
getLatestUrl

FILE=$(basename ${URL})
DEST=/tmp/$FILE

echo ""
echo -e "\e[94mDownloading Toolbox files \e[39m"
echo ""
retry wget -cO  ${DEST} ${URL} --read-timeout=5 --tries=0
echo ""
echo -e "\e[32mDownload complete!\e[39m"
echo ""
DIR="/opt/jetbrains-toolbox"
echo ""
echo  -e "\e[94mInstalling to $DIR\e[39m"
echo ""
if mkdir ${DIR}; then
    tar -xzf ${DEST} -C ${DIR} --strip-components=1
fi

echo  -e "\e[94mCreate /usr/local/bin/jetbrains-toolbox symbolic link\e[39m"
chmod -R +rwx ${DIR}
ln -s ${DIR}/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox

# configure jetbrain toolbox
mkdir -p /opt/jetbrains/lib
chown ${USERNAME}:${USERGROUP} /opt/jetbrains/lib

echo  -e "\e[94mRemove temporary files\e[39m"
echo ""
rm ${DEST}
echo  -e "\e[32mDone.\e[39m"