#!/bin/bash

#
# To be written
#
# Wrapper script for calling other scripts like so:
#
#   nix-script diff-generations 1 2
#
# So the "diff-generations" script looks like a command for "nix-script"
#

usage() {
    cat <<EOS >&2
    $(basename $0) [options] <command> <commandoptions>

    -l | --list-commands    List all available commands
    -c | --config           Use alternative configuration (rc) file
    -v                      Be verbose
    -h                      Show this help and exit

    (c) 2015 Matthias Beyer
    GPLv2 licensed
EOS
}

LIST_COMMANDS=0
VERBOSE=0
CONFIGFILE=~/.nixscriptsrc

stderr() {
    echo "[$(basename $0)]: $*" >&2
}

stdout() {
    [ $VERBOSE -eq 1 ] && echo "[$(basename $0)]: $*"
}

script_for() {
    echo "$(dirname ${BASH_SOURCE[0]})/nix-script-${1}.sh"
}

SHIFT_ARGS=0
shift_one_more() {
    SHIFT_ARGS=$(( SHIFT_ARGS + 1 ))
}

shift_n() {
    for n in `seq 0 $1`; do shift; done
    echo $*
}

all_commands() {
    find $(dirname ${BASH_SOURCE[0]}) -type f -name "nix-script-*.sh"
}

for cmd
do
    case $cmd in
    "--list-commands" )
        LIST_COMMANDS=1
        shift_one_more
        ;;

    "-l" )
        LIST_COMMANDS=1
        shift_one_more
        ;;

    "--config" )
        CONFIGFILE=$1
        shift_one_more
        ;;

    "-c" )
        CONFIGFILE=$1
        shift_one_more
        ;;

    "-v" )
        export VERBOSE=1
        stdout "Verbose now"
        shift_one_more
        ;;

    "-h" )
        usage
        exit 1
        ;;

    * )
        if [ ! -n $(script_for $cmd) ]
        then
            stderr "Unknown flag / command '$cmd'"
            exit 1
        else
            if [ -z "$COMMAND" ]
            then
                stdout "Found command: '$cmd'"
                COMMAND=$cmd
                shift_one_more
            fi
        fi
    esac
done

if [ ! -f $CONFIGFILE ]
then
    stderr "No config file: '$CONFIGFILE', won't override defaults"
else
    stdout "Source config: '$CONFIGFILE'"
    . $CONFIFILE
fi

if [ $LIST_COMMANDS -eq 1 ]
then
    stdout "Listing commands"
    for cmd in $(all_commands)
    do
        echo "$cmd"
    done
    exit 0
fi

if [ -z "$COMMAND" ]
then
    stderr "No command given"
    exit 0
fi

stdout "Searching for script for '$COMMAND'"
SCRIPT=$(script_for $COMMAND)

if [ ! -f $SCRIPT ]
then
    stderr "Not available: $COMMAND -> $SCRIPT"
    exit 1
fi

if [[ ! -x $SCRIPT ]]
then
    stderr "Not executeable: $SCRIPT"
    exit 1
fi

stdout "Parsing args for '$COMMAND'"
SCRIPT_ARGS=$(shift_n $SHIFT_ARGS $*)

stdout "Calling: '$COMMAND $SCRIPT_ARGS'"
exec bash $SCRIPT $SCRIPT_ARGS