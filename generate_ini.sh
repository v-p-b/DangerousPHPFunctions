#!/bin/bash

echo 'disabled_functions="'`grep -E -v '^\[|^\s*$' $1 | sort | tr '\n' ','| sed 's/,$//'`'"'

