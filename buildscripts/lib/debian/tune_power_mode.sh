#!/bin/bash

echo "=== Tuning Power Mode"
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
echo ""
