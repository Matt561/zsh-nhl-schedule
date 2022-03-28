# Daily NHL schedule in terminal

emulate -L zsh

DAILY_SCHEDULE_URL="https://statsapi.web.nhl.com/api/v1/schedule"

function getDailySchedule() {
    SCHEDULE=curl $DAILY_SCHEDULE_URL -H "Accept: application/json" 
    echo $SCHEDULE
}