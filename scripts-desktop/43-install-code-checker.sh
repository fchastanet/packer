#!/usr/bin/env bash

source /tmp/common.sh

# install nvm globally
mkdir "/usr/local/nvm"
chown -R ${USERNAME}:${USERGROUP} "/usr/local/nvm"
curl -o /tmp/install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION:-0.37.2}/install.sh
chmod 755 /tmp/install.sh
sudo -E -u ${USERNAME} bash -c "NVM_DIR=/usr/local/nvm /tmp/install.sh"
rm -f /tmp/install.sh

echo '
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
' >> /etc/profile
tail /etc/profile

# install node latest version
sudo -i -u ${USERNAME} bash -c "source /usr/local/nvm/nvm.sh && nvm install node"

# Install code checkers
# needed by php code sniffer: php-mbstring
# needed by composer : php-xml
retry apt-get install -y -q --no-install-recommends \
    php \
    php-mbstring \
    php-xml \
    shellcheck

# install composer last version
retry php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

# configure composer to be run as vagrant user
mkdir -p \
  /usr/local/.composer \
  ${USERHOME}/.config
chown ${USERNAME}:${USERGROUP} \
  /usr/local/.composer \
  ${USERHOME}/.config
sed -i -rn 's#PATH="([^"]+)"$#PATH="\1:/usr/local/.composer/vendor/bin"#p' /etc/environment
echo "COMPOSER_HOME=/usr/local/.composer" >> /etc/environment
source /etc/environment
rm -Rf ${USERHOME}/.config/composer || true

# linters
NODE_MODULES=(
    prettier
    sass-lint
    stylelint
)
CMD="cd "
CMD+=" && source /tmp/common.sh"
CMD+=" && retry npm install -g "
CMD+="${NODE_MODULES[@]}"

# php code sniffers
CMD+=' && retry composer global require "squizlabs/php_codesniffer=*"'
CMD+=' && retry composer global require "phpmd/phpmd=*"'
CMD+=' && retry composer global require "friendsofphp/php-cs-fixer=*"'

sudo -i -u ${USERNAME} bash -c "${CMD}"
