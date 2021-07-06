#!/bin/bash

# stdio [processid] [file]

cat ./testing/vscode/$2 > /proc/$1/fd/0

