#!/bin/bash

ps -A -o pid,command | grep z3.sh | while read line; do
        pid=$(echo $line | sed 's/^\([0-9]*\).*$/\1/g')
        echo "kill $pid"
        kill -9 $pid
done
 
ps -A -o pid,command | grep moea | while read line; do
        pid=$(echo $line | sed 's/^\([0-9]*\).*$/\1/g')
        echo "kill $pid"
        kill -9 $pid
done

ps -A -o pid,command | grep main | while read line; do
        pid=$(echo $line | sed 's/^\([0-9]*\).*$/\1/g')
        echo "kill $pid"
        kill -9 $pid
done

ps -A -o pid,command | grep mpirun | while read line; do
        pid=$(echo $line | sed 's/^\([0-9]*\).*$/\1/g')
        echo "kill $pid"
        kill -9 $pid
done

ps -A -o pid,command | grep octave | while read line; do
        pid=$(echo $line | sed 's/^\([0-9]*\).*$/\1/g')
        echo "kill $pid"
        kill -9 $pid
done

ps -A -o pid,command | grep submit_on_local.sh | while read line; do
        pid=$(echo $line | sed 's/^\([0-9]*\).*$/\1/g')
        echo "kill $pid"
        kill -9 $pid
done
