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
eval $(get_config "crawl_file_prefix" "links-report--")
eval $(get_config_path "crawl_file_directory" ".")
exit_with_failure_if_config_is_not_path "crawl_file_directory"
eval $(get_config -a "nofollow")
eval $(get_config -a "filter_level" 1)
eval $(get_config_keys "reports")

# Create a directory for output of reports for this host.
url_host=$(url_host ${website_url})
dirname=${crawl_file_directory%/}/${url_host%/}
[ -d "${dirname}" ] || mkdir "${dirname}" || exit_with_failure "Can't create reports directory ${dirname}"

# Handle other commands.
command=$(get_command)
case $command in

    "update")
        (cd $ROOT && yarn) || exit_with_failure "Missing yarn; cannot install node packages."
        exit_with_success_elapsed "Dependencies were updated."
        ;;

    "crawl")
        filename=${crawl_file_prefix}$(url_host $website_url)--$(date8601 -c)
        list_clear
        echo_title "Crawling ${url_host}"
        table_add_row "Entry point" ${website_url}
        table_add_row "Start time" $(time_local)
        table_add_row "Crawl file" "$(echo_green ${filename}.txt)"
        echo_slim_table
        if ! has_option "display"; then
            echo "Generating craw file to:"
            list_add_item "${dirname}/${filename}.txt"
        fi
        echo_list

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
            (cd $ROOT/node_modules/broken-link-checker/bin && ${command} > "${dirname}/${filename}.txt")
        fi
        has_failed && exit_with_failure
        exit_with_success_elapsed "Crawl finished."
        ;;

    "reports")
        crawl_file_filepath="$(get_command_arg 0)"

        # We allow users to drag from Finder onto Terminal, which gives us an
        # absolute link, then we'll strip the basename and hope we're in the
        # correct directory.
        if path_is_absolute "$crawl_file_filepath"; then
            crawl_file_filepath=$(basename $crawl_file_filepath)
            echo
            echo_yellow_highlight "Directory removed from absolute path; using: $crawl_file_filepath"
            echo
        fi
        crawl_file_filepath=$(path_resolve "${dirname}" $crawl_file_filepath)
        [ -f "$crawl_file_filepath" ] || exit_with_failure "$crawl_file_filepath does not exist."
        output_dir=$(dirname $crawl_file_filepath)

        if [ ${#reports[@]} -gt 0 ]; then

            list_clear
            echo "Creating reports in:"
            list_add_item "${output_dir}/"
            echo_list
            echo

            list_clear
            for key in "${reports[@]}"; do
               eval $(get_config_as "match" "reports.${key}.match")
               eval $(get_config_as "suffix" "reports.${key}.file_suffix")

               if has_option "display"; then
                   grep "${match}" ${crawl_file_filepath}
               else
                   report_basename="$(path_filename $crawl_file_filepath)--${suffix}.txt"
                   report_filepath="${output_dir}/${report_basename}"
                   if has_option "f"  || [ ! -f "$report_filepath" ] || confirm --danger "${report_basename} exists; overwrite?"; then
                       grep "${match}" ${crawl_file_filepath} > "${report_filepath}"
                       list_add_item "$(echo_green ${report_basename})"
                   else
                       list_add_item "$(echo "${report_basename} [skipped]")"
                   fi
               fi
            done
            echo "Report list:"
            echo_list
        else
          fail_because "There are no reports defined in the configuration."
        fi
        has_failed && exit_with_failure
        exit_with_success_elapsed "Reports ready."
        ;;

esac

throw "Unhandled command \"$command\"."
