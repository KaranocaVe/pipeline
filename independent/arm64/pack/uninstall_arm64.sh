#!/bin/bash

echo "=== Stopping ModelEngine ARM64 services... ==="

docker-compose down

echo "=== Services stopped ==="

read -p "Do you want to remove all data? (yes/no): " confirm
if [ "$confirm" == "yes" ]; then
    echo "Removing data directories..."
    rm -rf appengine/
    echo "Data removed."
else
    echo "Data preserved."
fi

echo "=== Uninstall finished ==="

