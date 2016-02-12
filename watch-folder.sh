#!/bin/sh

# This script checks a directory for files that have been changed.
# It mails a notice in this case.

if [ $# -ne 3 ]; then
	echo "Syntax:	$0 <mail-address> <directory> <excludefile>"
	exit 1
fi

mail="$1"
dir=`/usr/bin/readlink -f "$2"`
excludefile="$3"

# check if excludes file is readable
if [ ! -r "$excludefile" ]; then
	echo "Cannot read excludes file: $excludefile"
	exit 1
fi

mtreedirroot="$HOME/.mtree"
/bin/test -d "$mtreedirroot" || /bin/mkdir -p "$mtreedirroot"
mtreedirroot=`/usr/bin/readlink -f "$mtreedirroot"`

if [ "${mtreedirroot##$dir}" != "$mtreedirroot" ]; then
	echo "Error: you cannot watch this directory:"
	echo "$dir,"
	echo "because the status directory"
	echo "$mtreedirroot"
	echo " is stored inside it. It would always differ."
	exit 1
fi

mtreefile=${mtreedirroot}/`printf "%s" "$dir" | /sbin/sha256`.mtree
mygroup=`/usr/bin/id -gn`

# default keywords, see man
keywordspec="-k sha256 -nbx"

if [ -r "$mtreefile" ]; then
	#echo "Found $mtreefile."
	TMPF=`/usr/bin/mktemp /tmp/check.XXXXXX`
	/usr/sbin/mtree -p "$dir" $keywordspec -f "$mtreefile" -X "$excludefile" > "$TMPF"
	#/usr/bin/egrep -qv "^extra:" "$TMPF"
	if [ "$?" -eq 2 ]; then
		SUBJECT="Files in $dir have changed"
		/usr/bin/mail -s "$SUBJECT" "$mail" < "$TMPF"
		/bin/rm "$mtreefile"
	fi
	/bin/rm "$TMPF"
else
	echo "$mtreefile does not exist."
fi

if [ ! -r "$mtreefile" ]; then
	#echo "Creating $mtreefile."
	TMPF=`/usr/bin/mktemp /tmp/mtree.XXXXXX`
	/usr/sbin/mtree -p "$dir" -c $keywordspec -X "$excludefile" > "$TMPF"
	/bin/mv "$TMPF" "$mtreefile"
	/usr/bin/chgrp "$mygroup" "$mtreefile"
	/bin/chmod 600 "$mtreefile"
fi

exit 0
