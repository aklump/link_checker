# Link Checker

![link_checker](images/screenshot.jpg)

## Summary

Check your website for broken links.

## Quick Start

- Install in your repository root using `cloudy pm-install aklump/link_checker`
- Open _bin/config/link_checker.yml_ and set your config.
- Crawl your site and create reports with `.bin/link_checker crawl`

## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) and [yarn](https://yarnpkg.com/en/) installed on your system to install this package.

## Installation

The installation script above will generate the following structure where `.` is your repository root.

    .
    ├── bin
    │   ├── link_checker -> ../opt/link_checker/link_checker.sh
    │   └── config
    │       ├── link_checker.yml
    ├── opt
    │   ├── cloudy
    │   └── aklump
    │       └── link_checker
    └── {public web root}

    
### To Update

- Update to the latest version from your repo root: `cloudy pm-update aklump/link_checker`

## Configuration Files

| Filename | Description | VCS |
|----------|----------|---|
| _link_checker.yml_ | Configuration file  | yes |

## Usage

* To see all commands use `./bin/link_checker help`

## Contributing

If you find this project useful... please consider [making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Flink_checker).
