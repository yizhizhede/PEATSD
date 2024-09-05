#!/bin/bash

rm -f ./bin/main && make

valgrind --tool=memcheck --leak-check=full --log-file=memcheck.log -s ./bin/main

