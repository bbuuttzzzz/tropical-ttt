#!/bin/bash

YLW='\033[1;33m'
NC='\033[0m' # No Color

#define the function display_help
display_usage () {
    echo "Usage: gmds-link.sh [OPTION]... <PATH>"
    echo "Create symbolic links to attach this project to the Gmod Dedicated Server instance at PATH"
    echo -e "  -H, --hard\t\t\tdelete and recopy everything (will remove renamed/deleted files)"
    echo -e "  -R, --revert\t\t\tdelete everything. Don't copy"
    echo -e "  -f, --force\t\t\tdon't ask me if im sure I want to remove this directory"
}

#parse positional args
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -H|--hard)
            HARD=0
            shift # past argument
            ;;
#       -s|--searchpath)
#           SEARCHPATH="$2"
#           shift # past argument
#           shift # past value
#           ;;
        -R|--revert)
            REVERT=0
            shift # past argument
            ;;
        -f|--force)
            FORCE=0
            shift # past argument
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

#error check
if [[ $REVERT && $HARD ]]; then
    echo "ERROR: You can't use -R and -H at the same time."
fi

# if we didn't get a path
if [ -z "$1" ]; then
    display_usage #this is CALLING display_usage()
    return 1 2>/dev/null || exit "1"
fi

#if path isn't a GMDS root folder
grep -q 4000 $1/steam_appid.txt
if [[ $? -ne 0 ]]; then
    echo "ERROR: Invalid GMDS instance at $1"
    return 1 2>/dev/null || exit "1"
fi

# if we are reverting or hard reseting
if [[ $REVERT || $HARD ]]; then
    while read SOURCE DESTINATION ; do
        if [[ ${SOURCE:0:1} != "#" ]]; then
            if [[ $FORCE ]]; then
                rm -rf $1/$DESTINATION/`basename $SOURCE`
            else
                echo -e "${YLW}rm -rf $1/$DESTINATION/`basename $SOURCE`${NC}"
            fi
        fi
    done <gmds-copy-folders

    if [[ -z $FORCE ]]; then
        read -p "Really remove these folders? Yy/n" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy] ]]; then
            echo "Cancelling..."
            return 1 2>/dev/null || exit "1"
        else
            while read SOURCE DESTINATION ; do
                if [[ ${SOURCE:0:1} != "#" ]]; then
                    rm -rf $1/$DESTINATION/`basename $SOURCE`
                fi
            done <gmds-copy-folders
        fi
    fi
fi

# as long as we aren't reverting
if [[ -z $REVERT ]]; then
    while read SOURCE DESTINATION ; do
        if [[ ${SOURCE:0:1} != "#" ]]; then
            echo cp $SOURCE $1/$DESTINATION/
            mkdir -p $1/$DESTINATION
            cp -ru $SOURCE $1/$DESTINATION/
        fi
    done <gmds-copy-folders
fi
