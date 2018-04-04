#!/bin/sh
B=`pwd`

echo "current directory is $B"

if [ ! -f $B/buildbot.tac ]
then
    bbtravis create-master $B
    #cp /usr/src/buildbot/docker/buildbot.tac $B
fi

if [ -z "$BUILDBOT_CONFIG_URL" ]
then
    echo "No master.cfg found nor $$BUILDBOT_CONFIG_URL !"
    echo "Please provide a master.cfg file in $B or provide a $$BUILDBOT_CONFIG_URL variable via -e"
    exit 1

else
    BUILDBOT_CONFIG_DIR=${BUILDBOT_CONFIG_DIR:-config}
    mkdir -p $B/$BUILDBOT_CONFIG_DIR
    # if it ends with .tar.gz then its a tarball, else its directly the file
    if echo "$BUILDBOT_CONFIG_URL" | grep '.tar.gz$' >/dev/null
    then
        until curl -sL $BUILDBOT_CONFIG_URL | tar -xz --strip-components=1 --directory=$B/$BUILDBOT_CONFIG_DIR
        do
            echo "Can't download from \$BUILDBOT_CONFIG_URL: $BUILDBOT_CONFIG_URL"
            sleep 1
        done

        ln -sf $B/$BUILDBOT_CONFIG_DIR/master.cfg $B/master.cfg

        if [ -f $B/$BUILDBOT_CONFIG_DIR/buildbot.tac ]
        then
            ln -sf $B/$BUILDBOT_CONFIG_DIR/buildbot.tac $B/buildbot.tac
        fi
    else
        until curl -sL $BUILDBOT_CONFIG_URL > $B/master.cfg
        do
            echo "Can't download from $$BUILDBOT_CONFIG_URL: $BUILDBOT_CONFIG_URL"
        done
    fi
fi

# wait for pg to start by trying to upgrade the master
until buildbot upgrade-master $B
do
    sleep 1
done
exec twistd -ny $B/buildbot.tac
