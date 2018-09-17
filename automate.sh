#/bin/bash

ruby volatility_trends.rb
git add .
msg=`date`
git commit -m $msg  
git push origin
