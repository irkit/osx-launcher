#!/bin/sh

osacompile -o IRSender.scpt IRSender.applescript
Rez -append resources/IRSender.rsrc -o IRSender.scpt
SetFile -a C IRSender.scpt
cp IRSender.scpt "$HOME/Library/Application Support/Quicksilver/Actions/IRSender.scpt"
