#!/bin/bash
REP_DIR="$HOME/Configs/DotFiles/"
# Path to the file to monitor
ideavimrc=".ideavimrc"
# Path to Git's lock file
GIT_LOCK_FILE=".git/index.lock"

# Check if inotify-tools is installed
if ! command -v inotifywait &> /dev/null; then
    echo "Error: inotify-tools is not installed."
    echo "Please install it to use this script (e.g., 'sudo apt-get install inotify-tools')."
    exit 1
fi

#-------------- start of script -----------------

cd "$REP_DIR" || exit
# Initial size of the file
previous_size=$(stat -c %s "$ideavimrc")

echo "Watching $ideavimrc for changes..."

# Loop indefinitely
while inotifywait -q -e close_write "$ideavimrc"; do
    current_size=$(stat -c %s "$ideavimrc")

    if [ "$current_size" -ne "$previous_size" ]; then
        # Check if a Git operation is in progress by looking for the lock file
        if [ -f "$GIT_LOCK_FILE" ]; then
            echo "Git operation detected. Ignoring change to avoid commit loop."
        else
            echo "Change detected at $(date). Committing to git..."

            # Add only the specific file, commit, and push
            git add "$ideavimrc"
            git commit -m "Auto: Update $ideavimrc @ $(date '+%Y-%m-%d %H:%M:%S')"
            git push origin main

            echo "Push complete. Waiting for next change..."
        fi

        # IMPORTANT: Update the size regardless of the action to sync with the file's current state
        previous_size=$current_size
    fi
done
