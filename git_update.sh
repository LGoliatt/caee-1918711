#!/bin/bash

# Git Update Script with Enhanced Information

# Get current user and timestamp
USER=$(whoami)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
DATE_SHORT=$(date +"%Y-%m-%d")
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url 2>/dev/null) 2>/dev/null || echo "repository")

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Pull latest changes first (optional - can be skipped if you prefer)
echo "=== Pulling latest changes ==="
if ! git pull origin "$BRANCH"; then
    echo "Warning: Pull encountered issues. Continuing with update..."
fi

# Get status before adding
echo -e "\n=== Current Status ==="
git status --short

# Get changed files count
CHANGED_FILES=$(git status --porcelain | wc -l)
if [ "$CHANGED_FILES" -eq 0 ]; then
    echo -e "\nNo changes to commit."
    exit 0
fi

echo -e "\n=== Staging Changes ==="
git add .

# Create informative commit message
COMMIT_MSG="Update by $USER on $DATE_SHORT

Details:
- Timestamp: $TIMESTAMP
- Branch: $BRANCH
- Repository: $REPO_NAME
- Changed files: $CHANGED_FILES

Summary of changes:"

# Add list of changed files to commit message
CHANGED_LIST=$(git diff --cached --name-only)
if [ ! -z "$CHANGED_LIST" ]; then
    COMMIT_MSG="$COMMIT_MSG\n\nModified files:\n$CHANGED_LIST"
fi

# Commit with the detailed message
echo -e "\n=== Committing Changes ==="
echo -e "Commit message:\n"
echo -e "$COMMIT_MSG" | head -20
if [ $(echo "$COMMIT_MSG" | wc -l) -gt 20 ]; then
    echo "... (truncated, $(echo "$COMMIT_MSG" | wc -l) lines total)"
fi

# Use printf to preserve newlines in commit message
printf "%b" "$COMMIT_MSG" | git commit -F -

# Push to remote
echo -e "\n=== Pushing to Remote ==="
if git push origin "$BRANCH"; then
    echo -e "\n✅ Successfully updated repository!"
    echo "Branch: $BRANCH"
    echo "User: $USER"
    echo "Time: $TIMESTAMP"
else
    echo -e "\n❌ Push failed. Please check your remote repository."
    exit 1
fi