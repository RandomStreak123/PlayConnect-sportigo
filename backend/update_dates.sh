#!/bin/bash
# Run the Laravel command to update match dates relative to NOW() dynamically
cd /home/ajith/Project3/backend

echo "=== Updating match dates dynamically ==="
ddev artisan app:update-match-dates
