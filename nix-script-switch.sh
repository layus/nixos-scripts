#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

CONFIG_DIR=

COMMAND="switch"

usage() {
    cat <<EOS

    $(help_synopsis "${BASH_SOURCE[0]}" "[-h] [-c <command>] [-g <git command>] -w <working directory> [-- args...]")

        -c <command>    Command for nixos-rebuild. See 'man nixos-rebuild'
        -g <git cmd>    Alternative git commit, defaults to 'tag -a'
        -w <path>       Path to your configuration git directory
        -n              Don't actually call nixos-rebuild and just generate a tag
        -h              Show this help and exit

        Everything after a double dash (--) will be passed to nixos-rebuild as
        additional parameters. For example:

            nix-script switch -c switch -- -I nixpkgs=/home/user/pkgs

$(help_end)
EOS
}

COMMAND=
ARGS=
WD=
TAG_NAME=
GIT_COMMAND=
JUST_TAG=

while getopts "c:w:t:g:nh" OPTION
do
    case $OPTION in
        c)
            COMMAND=$OPTARG
            stdout "COMMAND = $COMMAND"
            ;;
        w)
            WD=$OPTARG
            stdout "WD = $WD"
            ;;
        t)
            TAG_NAME=$OPTARG
            stdout "TAG_NAME = $TAG_NAME"
            ;;

        g)
            GIT_COMMAND=$OPTARG
            stdout "GIT_COMMAND = $GIT_COMMAND"
            ;;

        n)
            JUST_TAG=1
            stdout "JUST_TAG = $JUST_TAG"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

ARGS=$(echo $* | sed -r 's/(.*)\-\-(.*)/\2/')
stdout "ARGS = $ARGS"

if [[ -z "$WD" ]]
then
    stderr "No configuration git directory."
    stderr "Won't do anything"
    exit 1
fi

if [[ ! -d "$WD" ]]
then
    stderr "No directory: $WD"
    exit 1
fi

if [[ -z "$COMMAND" ]]
then
    COMMAND="switch"
fi

if [[ -z "$GIT_COMMAND" ]]
then
    GIT_COMMAND="tag -a"
fi

if [[ -z "$JUST_TAG" ]]
then
    explain sudo nixos-rebuild $COMMAND $ARGS
    REBUILD_EXIT=$?
else
    stdout "Do not call nixos-rebuild"
    REBUILD_EXIT=0
fi

if [[ $REBUILD_EXIT -eq 0 ]]
then
    stdout 'Trying: sudo nix-env -p /nix/var/nix/profiles/system' \
           '--list-generations | grep current | awk -F' ' '{ print $1 }''
    LASTGEN=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations |\
        grep current | awk -F' ' '{ print $1 }')
    sudo -k

    stdout "sudo -k succeeded"
    stdout "Last generation was: $LASTGEN"

    if [[ -z "$TAG_NAME" ]]
    then
        TAG_NAME="nixos-$LASTGEN-$COMMAND"
        stdout "Tag name will be default generated : '$TAG_NAME'"
    fi

    explain git --git-dir="$WD/.git" --work-tree="$WD" $GIT_COMMAND "'$TAG_NAME'"

else
    stderr "Switching failed. Won't executing any further commands."
    exit $REBUILD_EXIT
fi

