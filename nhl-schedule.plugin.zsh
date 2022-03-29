# Daily NHL schedule in terminal
function nhl-schedule() {
    # See if dependency is installed
    _isJqInstalled
    is_jq_installed=$?
    if [[ "$is_jq_installed" == 1 ]]; then
        echo "Missing dependency \"jq\"\nInstall it by running: brew install jq"
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
            *) _displayTodaysGames ;;
        esac 
    done
}


function _displayHelpMenu() {
    echo "NHL Schedule Plugin"
    echo "displays the NHL schedule within your terminal\n"
    echo "Usage:"
    echo "nhl-schedule"
    echo "nhl-scedule -t=<team_nam>"
    echo "nhl-schedule -h"

    echo "\nOptions:"
    echo "-h                Show help screen"
    echo "-d <yyyy-mm-dd>   Display games for specific date in yyyy-mm-dd format (past or future dates accepted)"
    echo "-t <team_name>    Display schedule for specific team; Ex. Toronto Maple Leafs"
    echo "-x <division>     Display schedule for a division"
    echo "-c <conference>   Display schedule for a conference"
    echo "\nBy default, nhl-schedule displays all games for today's date"
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

    for row in $(echo "${game_list}" | jq -r '.[] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }
        
        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        
        lowercase_away_team=${away_team:l}
        lowercase_home_team=${home_team:l}

        counter=0

        # check if team is in matchup
        if [[ $1 == $lowercase_away_team ]] || [[ $1 == $lowercase_home_team ]]; then
            echo "$away_team vs. $home_team"
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
        
        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        echo "$away_team vs. $home_team"

    done
}

function _displayTodaysGames() {
    nhl_api_url="https://statsapi.web.nhl.com/api/v1/schedule"
    json_response=$(curl -s $nhl_api_url -H "Accept: application/json")

    date=$( echo $json_response | jq '.dates[0].date')
    game_count=$(echo $json_response | jq '.dates[0].totalGames')
    game_list=$(echo $json_response | jq '.dates[0].games')

    echo "$game_count games today ($date)"

    for row in $(echo "${game_list}" | jq -r '.[] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }
        
        away_team=$(echo $(_jq '.teams.away.team.name'))
        home_team=$(echo $(_jq '.teams.home.team.name'))
        echo "$away_team vs. $home_team"

    done
}
