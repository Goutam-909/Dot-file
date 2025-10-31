#!/bin/bash

# Kill existing swaync process
pkill -9 swaync

# Wait for a moment to make sure the process is terminated
sleep 0.5

# Restart swaync
swaync &
