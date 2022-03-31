#!/bin/bash 
# Daily NHL schedule in terminal
function nhl-schedule() {

    # See if dependencies are installed
    _areGnuCoreUtilsInstalled
    are_coreutils_installed=$?
    if [[ "$are_coreutils_installed" == 1 ]]; then
        echo "Missing dependency \"GNU coreutils\"\nInstall it by running: brew install coreutils"
        return
    fi

    _isJqInstalled
    is_jq_installed=$?
    if [[ "$is_jq_installed" == 1 ]]; then
        echo "Missing dependency \"jq\"\nInstall it by running: brew install jq"
        return
    fi

    # Default command without options
    if [[ $# -eq 0 ]]; then
        _displayTodaysGames
        return
    fi

    # if flag is followed by a colon it is expected to have an argument
    while getopts 'ht:d:c:x:' flag; do
        case "${flag}" in
            h) _displayHelpMenu ;;
            t) _displaySelectTeamsGames ${OPTARG} ;;
            d) _displayGamesAtDate ${OPTARG} ;;
            c) echo "display games for ${OPTARG} conference" ;;
            x) echo "display games for ${OPTARG} division" ;;
        esac
    done
}


function _displayHelpMenu() {
    printf "NHL Schedule Plugin \U1F3D2\n"
    echo "displays the NHL schedule within your terminal\n"
    echo "Usage:"
    echo "nhl-schedule"
    echo "nhl-schedule -t \"<team_name>\""
    echo "nhl-schedule -x \"<division_name>\""
    echo "nhl-schedule -c \"<conference_name>\""
    echo "nhl-schedule -d \"<yyyy-mm-dd>\""
    echo "nhl-schedule -h"

    echo "\nOptions:"
    echo "-h                Show help screen"
    echo "-d <yyyy-mm-dd>   Display games for specific date in yyyy-mm-dd format (past or future dates accepted)"
    echo "-t <team_name>    Display schedule for specific team; Ex. Toronto Maple Leafs"
    echo "-x <division>     Display schedule for a division"
    echo "-c <conference>   Display schedule for a conference"
    echo "\nBy default, nhl-schedule displays all games for today's date"
    echo "\nWritten by Matthew Grainger"
}

function _areGnuCoreUtilsInstalled() {
        are_coreutils_installed=$(gdate --version 2> /dev/null | grep  "date (GNU coreutils)*")

    if ! [[ "$are_coreutils_installed" == "date (GNU coreutils)"* ]]; then
        return 1;
    fi

    return 0;
}

function _isJqInstalled() {
    is_jq_installed=$(jq --version 2> /dev/null | grep  "jq-*")

    if ! [[ "$is_jq_installed" == "jq-"* ]]; then
        return 1;
    fi

    return 0;
}

function _displaySelectTeamsGames() {
    nhl_api_url="https://statsapi.web.nhl.com/api/v1/schedule"
    json_response=$(curl -s $nhl_api_url -H "Accept: application/json")

    date=$( echo $json_response | jq '.dates[0].date')
    game_count=$(echo $json_response | jq '.dates[0].totalGames')
    game_list=$(echo $json_response | jq '.dates[0].games')

    counter=0

    for row in $(echo "${game_list}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        
        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        
        lowercase_away_team=${away_team:l}
        lowercase_home_team=${home_team:l}

        game_time=$(echo $(_jq '.gameDate'))
        game_time_local=$(gdate -d$game_time +"%H:%M")

        user_input_lowercase=${1:l}
        
        # check if team is in matchup
        if [[ $user_input_lowercase == $lowercase_away_team ]] || [[ $1 == $lowercase_home_team ]]; then
            echo "$away_team vs. $home_team ($game_time_local)"
            counter=$((counter + 1))
        fi
    done


    if [[ $counter == 0 ]]; then
        echo "The $1 don't have any games today"
    fi
}

function _displayGamesAtDate() {
    nhl_api_url="https://statsapi.web.nhl.com/api/v1/schedule?date=$1"
    json_response=$(curl -s $nhl_api_url -H "Accept: application/json")

    date=$( echo $json_response | jq '.dates[0].date')
    game_count=$(echo $json_response | jq '.dates[0].totalGames')
    game_list=$(echo $json_response | jq '.dates[0].games')

    echo "$game_count games on ($date)"

    for row in $(echo "${game_list}" | jq -r '.[] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }
        
        game_time=$(echo $(_jq '.gameDate'))
        echo "time: $game_time"
        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        echo "$away_team vs. $home_team ($game_time)"

    done
}

function _displayTodaysGames() {
    nhl_api_url="https://statsapi.web.nhl.com/api/v1/schedule"
    json_response=$(curl -s $nhl_api_url -H "Accept: application/json")

    date=$( echo $json_response | jq '.dates[0].date')
    game_count=$(echo $json_response | jq '.dates[0].totalGames')
    game_list=$(echo $json_response | jq '.dates[0].games')

    echo "$game_count NHL games today ($date)"

    for row in $(echo "${game_list}" | jq -r '.[] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }
        
        game_time=$(echo $(_jq '.gameDate'))
        game_time_local=$(gdate -d$game_time +"%H:%M")

        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        echo "$away_team vs. $home_team [$game_time_local]"

    done
}
