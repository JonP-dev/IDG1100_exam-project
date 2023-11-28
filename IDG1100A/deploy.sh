#!/bin/bash

# configuring how the script will run - with extra debug info and exiting on errors right away
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
RESOURCE_DIR="${SCRIPT_DIR}/resources"
SITE_NAME="lucky.url"
ADMIN_EMAIL="aliaksei@manscaped.com"
DEST_DIR="/var/www/goodness-gracious"

function schedule_weather_checks() {
    # removing/re-adding the line with the weather check
    crontab -l |\
        sed "/check\.weather\.sh/d" |\
        cat - <(echo "*/10 * * * * $SCRIPT_DIR/check.weather.sh") |\
        crontab
    # echo "skipping crontab with weather check"
}

function config_apache() {
    # copy .conf in /etc/apache2/sites-available; while also customizing it
    cat "${RESOURCE_DIR}/template.apache.conf" |
        sed "s/<<url>>/$SITE_NAME/g" |
        sed "s <<rootDir>> $DEST_DIR g" |
        sed "s/<<email>>/$ADMIN_EMAIL/g" |
        sudo tee "/etc/apache2/sites-available/${SITE_NAME}.conf" > "/dev/null"
    # make sure the site is Apache-enabled
    sudo a2ensite "${SITE_NAME}.conf"
    # make sure /etc/hosts has our URL for testing
    if ! grep -q "$SITE_NAME" /etc/hosts; then
        echo "127.0.0.1 $SITE_NAME" | sudo tee -a /etc/hosts
    fi
    # enable cgi scripts on apache
    sudo a2enmod cgi
    sudo systemctl restart apache2

}

source "$SCRIPT_DIR/main.sh" &&
    source "$SCRIPT_DIR/check.weather.sh" &&
    schedule_weather_checks &&
    source "$SCRIPT_DIR/update.pages.sh" &&
    config_apache

# restoring the initial script-running configuration
set +ex
