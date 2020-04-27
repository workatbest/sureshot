#/bin/bash

PS3='Please enter your choice: '
options=("Daily" "SMA-EMA" "BEAR-BULL" "Options" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Daily")
            echo "Running Daily Run"
            ruby volatility_trends.rb
            break
            ;;
        "SMA-EMA")
            echo "Running SMA-EMA indicators"
            ruby indicators.rb
            break
            ;;
        "BEAR-BULL")
            echo "Running BEAR-BULL indicators"
            ruby bear_bull.rb
            break
            ;;
        "Options")
            echo "Running options indicators"
            ruby options_data.rb
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
git add .
msg=`date`
git commit -m "$msg"  
git push origin
