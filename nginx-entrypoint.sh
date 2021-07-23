#!/bin/sh

bash generate-env-file.sh /usr/share/nginx/html/env.js

[ -z "$@" ] && nginx -g 'daemon off;' || $@
