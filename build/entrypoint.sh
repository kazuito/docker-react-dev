#!/bin/sh -e

USER_ID=`id -u`
GROUP_ID=`id -g`

# グループを作成する
if [ "$GROUP_ID" != "0" ]; then
    addgroup -g $GROUP_ID $USER_NAME
fi

# ユーザを作成する
if [ "$USER_ID" != "0" ]; then
    adduser -u $USER_ID -g $GROUP_ID $USER_NAME
fi

# パーミッションを元に戻す
sudo chmod -s /usr/sbin/adduser /usr/sbin/addgroup

exec $@
