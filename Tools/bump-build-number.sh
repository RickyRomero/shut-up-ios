# This script is based on the script provided at http://stackoverflow.com/questions/9258344/xcode-better-way-of-incrementing-build-number
# The only difference is, that it uses hexadecimal build numbers instead of decimal ones.
# For instructions on how to use this script, see the link above.


#!/bin/sh

if [ $# -ne 1 ]; then
  echo usage: $0 plist-file
	exit 1
fi

plist="$1/Shut Up/Info.plist"
extplist="$1/comment blocker/Info.plist"

dir="$(dirname "$plist")"

# Only increment the build number if source files have changed
if [ -n "$(find "$dir" \! -path "*xcuserdata*" \! -path "*.git" -newer "$plist")" ]; then
	buildnum=$(/usr/libexec/Plistbuddy -c "Print CFBundleVersion" "$plist")
	if [ -z "$buildnum" ]; then
		echo "No build number in $plist"
		exit 2
	fi
	buildnum=$(expr $buildnum + 1)

	# Update all plist files.
	/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "$plist"
	/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "$extplist"
	echo "Incremented build number to $buildnum"
else
	echo "Not incrementing build number as source files have not changed"
fi