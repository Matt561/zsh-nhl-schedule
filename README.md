# zsh-nhl-schedule
zsh plugin that retrieves and displays the NHL's schedule


### Oh My Zsh Installation

1. Clone this repository into $ZSH_CUSTOM/plugins (by default ~/.oh-my-zsh/custom/plugins)
```
git clone https://github.com/Matt561/zsh-nhl-schedule.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/nhl-schedule
```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside ~/.zshrc):
```
plugins=( 
    # other plugins...
    nhl-schedule
)
```
---
Dependencies

 [jq](https://stedolan.github.io/jq/) - A lightweight command-line JSON processor
 Used to parse JSON response from NHL API
 
 ```brew install jq```
 
 [GNU coreutils](https://www.gnu.org/software/coreutils/) - the basic file, shell and text manipulation utilities of the GNU operating system.
 Used for the date command to convert timestamps to the user's local timezone 
 
 ```brew install coreutils```
 
Example output

<img width="446" alt="image" src="https://user-images.githubusercontent.com/46547583/160956081-6ab94762-3b5f-4278-8d3c-7d01cf0e8b77.png">

Help menu

<img width="935" alt="image" src="https://user-images.githubusercontent.com/46547583/160959892-2a6c3f1f-5dca-4763-992a-cb03733d1b8f.png">
