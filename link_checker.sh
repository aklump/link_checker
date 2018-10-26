#!/usr/bin/env bash

#
# @file
# Link Checker will crawl your site and generate reports.
#

# Define the configuration file relative to this script.
CONFIG="link_checker.core.yml";

# Uncomment this line to enable file logging.
#LOGFILE="link_checker.core.log"

function on_pre_config() {
    if [[ "$(get_command)" == "init" ]]; then
        yarn || exit_with_failure "Missing yarn; cannot install node packages."
        exit_with_init
    fi
}

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/../../cloudy/cloudy/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$(tput sgr0)" && exit 1
# End Cloudy Bootstrap

# Input validation.
validate_input || exit_with_failure "Input validation failed."

implement_cloudy_basic

eval $(get_config "website_url")
exit_with_failure_if_empty_config "website_url"
eval $(get_config "report_basename" "links-report--")
eval $(get_config_path "report_dir" ".")
exit_with_failure_if_config_is_not_path "report_dir"
eval $(get_config -a "subreports")

# Handle other commands.
command=$(get_command)
case $command in

    "crawl")
    url_host=$(url_host $website_url)

    # Create a directory for output of reports for this host.
    dirname=${report_dir%/}/${url_host}
    [ -d $dirname ] || mkdir $dirname || exit_with_failure "Can't create reports directory $dirname"
    basename=${report_basename}$(url_host $website_url)--$(date8601 -c)

    list_clear
    echo_heading "Crawling $url_host..."
    list_add_item "$basename.txt"
    echo_green_list

    # Crawl the site using https://github.com/stevenvachon/broken-link-checker
    (cd $ROOT/node_modules/broken-link-checker/bin && blc ${website_url} -ro > "${dirname%/}/$basename.txt")

    # Generate subreports if asked.
    if [ ${#subreports[@]} -gt 0 ]; then
        echo "Creating subreports in ${dirname%/}/"
        list_clear
        for status in "${subreports[@]}"; do
            list_add_item "${basename}--${status}.txt"
            grep "$status" ${dirname%/}/$basename.txt > "${dirname%/}/${basename}--${status}.txt"
        done
        echo_green_list
    fi
    has_failed && exit_with_failure
    exit_with_success "Reports ready."
    ;;

esac

throw "Unhandled command \"$command\"."
