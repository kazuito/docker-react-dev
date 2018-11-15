#!/bin/sh -e

USER_ID=`id -u`
GROUP_ID=`id -g`

# ユーザを作成する
if [ "$USER_ID" != "0" ]; then
    export HOME=/tmp
fi

exec $@
