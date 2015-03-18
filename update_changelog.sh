#!/bin/bash

new_changelog_entry() {
cat <<EOF
nginx ($NGINX_VERSION+edh) wheezy; urgency=low
  * Update to upstream version $NGINX_VERSION
  * Includes custom EDH modules.

 -- Dan Sowter <daniel.sowter@everydayhero.com>  Tue, 17 Mar 2015 14:40:14 +1000

EOF
}

cat <(new_changelog_entry) /tmp/${NGINX_SOURCE_FOLDER}/debian/changelog > temp_changelog
mv temp_changelog /tmp/${NGINX_SOURCE_FOLDER}/debian/changelog
