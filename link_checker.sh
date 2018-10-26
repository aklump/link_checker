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
        (cd $ROOT && yarn) || exit_with_failure "Missing yarn; cannot install node packages."
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
eval $(get_config -a "nofollow")
eval $(get_config -a "filter_level" 1)

# Handle other commands.
command=$(get_command)
case $command in

    "check")
        url_host=$(url_host $website_url)

        # Create a directory for output of reports for this host.
        dirname=${report_dir%/}/${url_host%/}
        [ -d $dirname ] || mkdir $dirname || exit_with_failure "Can't create reports directory $dirname"
        basename=${report_basename}$(url_host $website_url)--$(date8601 -c)

        list_clear
        echo_title "Crawling $url_host..."
        echo_heading "Start time is $(echo_yellow $(time_local))"
        echo
        if ! has_option "display"; then
            echo "Writing report to:"
            list_add_item "${dirname}/${basename}.txt"
        fi
        echo_green_list

        # Crawl the site using https://github.com/stevenvachon/broken-link-checker
        declare -a options=('-ro' "--filter-level=${filter_level}");
        if has_option "verbose"; then
            options=("${options[@]}" "-v")
        fi

        # Add in our nofollow configuration, if there.
        for pattern in "${nofollow[@]}"; do
           options=("${options[@]}" "--exclude=${pattern}")
        done
        command="blc ${website_url} ${options[@]}"

        if has_option "display"; then
            (cd $ROOT/node_modules/broken-link-checker/bin && ${command})
        else
            (cd $ROOT/node_modules/broken-link-checker/bin && ${command} > "${dirname}/${basename}.txt")
        fi

        # Generate sub-reports if asked.
        if [ ${#subreports[@]} -gt 0 ]; then
            echo "Creating sub-reports in ${dirname}/"
            list_clear
            for status in "${subreports[@]}"; do
                if has_option "display"; then
                    grep "$status" ${dirname}/${basename}.txt
                else
                    list_add_item "${basename}--${status}.txt"
                    grep "$status" ${dirname}/${basename}.txt > "${dirname}/${basename}--${status}.txt"
                fi
            done
            echo_green_list
        fi
        has_failed && exit_with_failure
        exit_with_success_elapsed "Reports ready."
    ;;

    "reports")
        filepath=$(get_command_arg 0)
        dirname=$(dirname $filepath)
        basename=$(path_filename $filepath)

        if [ ${#subreports[@]} -gt 0 ]; then
            echo "Creating sub-reports in ${dirname}/"
            list_clear
            for status in "${subreports[@]}"; do
                if has_option "display"; then
                    grep "$status" ${dirname}/${basename}.txt
                else
                    list_add_item "${basename}--${status}.txt"
                    grep "$status" ${dirname}/${basename}.txt > "${dirname}/${basename}--${status}.txt"
                fi
            done
            echo_green_list
        fi
        has_failed && exit_with_failure
        exit_with_success_elapsed "Reports ready."
    ;;

esac

throw "Unhandled command \"$command\"."
