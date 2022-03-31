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
    # Show scores
    elif [[ $1 == "-s" ]]; then
        _displayTodaysGames $1
        return
    fi

    # if flag is followed by a colon it is expected to have an argument
    while getopts 'ht:d:s' flag; do
        case "${flag}" in
            h) _displayHelpMenu ;;
            t) _displaySelectTeamsGames ${OPTARG} $3 ;;
            d) _displayGamesAtDate ${OPTARG} ;;
        esac
    done
}


function _displayHelpMenu() {
    printf "NHL Schedule Plugin \U1F3D2\n"
    echo "displays the NHL schedule within your terminal\n"
    echo "Usage:"
    echo "nhl-schedule"
    echo "nhl-schedule -s"
    echo "nhl-schedule -t \"<team_name>\""
    echo "nhl-schedule -t \"<team_name>\" -s"
    echo "nhl-schedule -d \"<yyyy-mm-dd>\""
    echo "nhl-schedule -h"
    
    echo "\nOptions:"
    echo "-h                Show help screen"
    echo "-s                Display games with live scores"
    echo "-d <yyyy-mm-dd>   Display games for specific date in yyyy-mm-dd format (past or future dates accepted)"
    echo "-t <team_name>    Display schedule for specific team; Ex. Toronto Maple Leafs"
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
    should_show_scores=0

    if  [[ $2 == "-s" ]]; then
        should_show_scores=$((should_show_scores + 1))
    fi

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
        away_team_score=$(echo $(_jq '.teams.away.score'))

        home_team=$(echo $(_jq '.teams.home.team.name'))
        home_team_score=$(echo $(_jq '.teams.home.score'))

        lowercase_away_team=${away_team:l}
        lowercase_home_team=${home_team:l}

        game_time=$(echo $(_jq '.gameDate'))
        game_time_local=$(gdate -d$game_time +"%H:%M")
        game_state=$(echo $(_jq '.status.abstractGameState'))

        user_input_lowercase=${1:l}
        
        # check if team is in matchup
        if [[ $user_input_lowercase == $lowercase_away_team ]] || [[ $1 == $lowercase_home_team ]]; then
            # check if should show scores
            if [[ $should_show_scores == 1 ]] && [[ $game_state == 'Live' ]]; then
                echo "$away_team ($away_team_score) vs. $home_team ($home_team_score)"
            else
                echo "$away_team vs. $home_team ($game_time_local)"
            fi    
            counter=$((counter + 1))
            return
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
        game_time_local=$(gdate -d$game_time +"%H:%M")

        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        echo "$away_team vs. $home_team ($game_time_local)"

    done
}

function _displayTodaysGames() {
    should_show_scores=0

    if  [[ $1 == "-s" ]]; then
        should_show_scores=$((should_show_scores + 1))
    fi

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
        game_state=$(echo $(_jq '.status.abstractGameState'))

        game_time_local=$(gdate -d$game_time +"%H:%M")

        away_team=$(echo $(_jq '.teams.away.team.name'))
        away_team_score=$(echo $(_jq '.teams.away.score'))

        home_team=$(echo $(_jq '.teams.home.team.name'))
        home_team_score=$(echo $(_jq '.teams.home.score'))

        if [[ $should_show_scores == 1 ]] && [[ $game_state == "Live" ]]; then
            echo "$away_team ($away_team_score) vs. $home_team ($home_team_score)"
        else
            echo "$away_team vs. $home_team [$game_time_local]"
        fi

    done
}
