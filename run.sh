#/bin/bash

PS3='Please enter your choice: '
options=("Daily" "SMA-EMA" "BEAR-BULL" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Daily")
            echo "Running Daily Run"
            ruby volatility_trends.rb
            ;;
        "SMA-EMA")
            echo "Running SMA-EMA indicators"
            ruby indicators.rb
            ;;
        "BEAR-BULL")
            echo "Running BEAR-BULL indicators"
            ruby bear_bull.rb
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
