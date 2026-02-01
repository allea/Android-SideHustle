#!/bin/bash

if [ -z "$1" ]; then
  echo "Error: Version name is required."
  echo "Usage: $0 <VersionName>"
  exit 1
fi

VERSION_NAME="$1"
VERSION_NAME="${VERSION_NAME#v}"

CHANGELOG_PATH="./CHANGELOG.md"
if [ ! -f "$CHANGELOG_PATH" ]; then
  echo "Error: Changelog file '$CHANGELOG_PATH' not found."
  exit 1
fi

CHANGELOG_CONTENT=$(cat "$CHANGELOG_PATH")

RELEASE_NOTES=$(echo "$CHANGELOG_CONTENT" | \
  VERSION="$VERSION_NAME" perl -0777 -ne 'my $ver = $ENV{VERSION}; if (/## \[\Q$ver\E[^\]]*\].*?\n(.*?)(?=## \[|\z)/s) { print $1; }')

if [ -n "$RELEASE_NOTES" ]; then
  echo "$RELEASE_NOTES" | sed 's/\r//g'
else
  # For pre-release/beta versions or missing changelog entries, provide a default message
  echo "Release $VERSION_NAME"
  echo ""
  echo "See the full changelog at: https://github.com/allea/Android-SideHustle/blob/main/CHANGELOG.md"
fi

exit 0
