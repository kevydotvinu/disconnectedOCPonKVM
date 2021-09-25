#!/bin/bash

function USAGE {
        echo "OpenShift Upgrade Path Check"
        echo ""
        echo "This script helps you to check the OpenShift upgrade path"
        echo ""
        echo "Usage:"
        echo "  bash $0 -c [channel] -v [current-version]"
        echo ""
        echo "Options"
        echo "  -c: Channel name. Ex:"
        echo "      stable-4.8"
        echo "  -v: Current version. Ex:"
        echo "      4.7.13" 1>&2; exit 1;
}

while getopts ":c:v:" o; do
    case "${o}" in
        c)
            c=${OPTARG}
            ;;
        v)
            v=${OPTARG}
            curl -sH 'Accept:application/json' "https://api.openshift.com/api/upgrades_info/v1/graph?channel=${c}" | jq -r --arg CURRENT_VERSION "${v}" '. as $graph | $graph.nodes | map(.version=='\"${v}\"') | index(true) as $orig | $graph.edges | map(select(.[0] == $orig)[1]) | map($graph.nodes[.].version) | sort_by(.)'
            ;; 
        *)
            USAGE
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${c}" ] || [ -z "${v}" ]; then
    USAGE
fi
