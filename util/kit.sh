#!/bin/sh
#
# Copyright (C) 2004, 2005, 2009  Internet Systems Consortium, Inc. ("ISC")
# Copyright (C) 2000-2003  Internet Software Consortium.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# $Id: kit.sh,v 1.27.18.5 2009/07/16 23:46:08 tbox Exp $

# Make a release kit
#
# Usage: sh kit.sh tag tmpdir
#
#    (e.g., sh kit.sh v9_0_0b5 /tmp/bindkit
#
# To build a snapshot release, use the pseudo-tag "snapshot".
#
#   (e.g., sh kit.sh snapshot /tmp/bindkit
#

arg=-r
case $# in
    3)
	case "$1" in
	snapshot) ;;
	*) echo "usage: sh kit.sh [snapshot] cvstag tmpdir" >&2
	   exit 1
	   ;;
	esac
	snapshot=true;
	releasetag=$2
	tag=$2
	tmpdir=$3
	;;
    2)
	tag=$1
	tmpdir=$2
	case $tag in
	    snapshot) tag=HEAD; snapshot=true ; releasetag="" ;;
	    *) snapshot=false ;;
	esac
	;;
    *) echo "usage: sh kit.sh [snapshot] cvstag tmpdir" >&2
       exit 1
       ;;
esac



test -d $tmpdir ||
mkdir $tmpdir || {
    echo "$0: could not create directory $tmpdir" >&2
    exit 1
}

cd $tmpdir || exit 1

cvs checkout -p -r $tag bind9/version >version.tmp
. ./version.tmp


if $snapshot
then
    set `date -u +'%Y%m%d%H%M%S %Y/%m/%d %H:%M:%S UTC'`
    dstamp=$1
    RELEASETYPE=s
    RELEASEVER=${dstamp}${releasetag}
    shift
    tag="$@"
    arg=-D
fi

version=${MAJORVER}.${MINORVER}.${PATCHVER}${RELEASETYPE}${RELEASEVER}

echo "building release kit for BIND version $version, hold on..."

topdir=bind-$version

test ! -d $topdir || {
    echo "$0: directory `pwd`/$topdir already exists" >&2
    exit 1
}

cvs -Q export $arg "$tag" -d $topdir bind9

cd $topdir || exit 1

if $snapshot
then
    cat <<EOF >version
MAJORVER=$MAJORVER
MINORVER=$MINORVER
PATCHVER=$PATCHVER
RELEASETYPE=$RELEASETYPE
RELEASEVER=$RELEASEVER
EOF
fi

# Omit some files and directories from the kit.
#
# Some of these directories (doc/html, doc/man...) no longer
# contain any files and should therefore be absent in the
# checked-out tree, but they did exist at some point and
# we still delete them from releases just in case something 
# gets accidentally resurrected.

rm -rf TODO EXCLUDED conftools util doc/design doc/dev doc/expired \
    doc/html doc/todo doc/private bin/lwresd doc/man \
    lib/lwres/man/resolver.5 \
    bin/tests/system/relay lib/cfg

find . -name .cvsignore -print | xargs rm

# The following files should be executable.
chmod +x configure install-sh mkinstalldirs \
	 lib/bind/configure lib/bind/mkinstalldirs \
	 bin/tests/system/ifconfig.sh

# Fix files which should be using DOS style newlines
windirs=`find lib bin -type d -name win32`
windirs="$windirs win32utils"
winnames="-name *.mak -or -name *.dsp -or -name *.dsw -or -name *.txt -or -name *.bat"
for f in `find $windirs -type f \( $winnames \) -print`
do
	awk '{sub("\r$", "", $0); printf("%s\r\n", $0);}' < $f > tmp
	touch -r $f tmp
	mv tmp $f
done

# check that documentation has been updated properly; issue a warning
# if it hasn't
if test doc/arm/Bv9ARM-book.xml -nt doc/arm/Bv9ARM.html
then
	echo "WARNING: ARM source is newer than the html version."
fi

if test doc/arm/Bv9ARM-book.xml -nt doc/arm/Bv9ARM.pdf
then
	echo "WARNING: ARM source is newer than the PDF version."
fi

for f in `find . -name "*.docbook" -print`
do
	docbookfile=$f
	htmlfile=${f%.docbook}.html
	if test $docbookfile -nt $htmlfile
	then
		echo "WARNING: $docbookfile is newer than the html version."
	fi
done

# build the tarball
cd .. || exit 1

kit=$topdir.tar.gz

tar -c -f - $topdir | gzip > $kit

echo "done, kit is in `pwd`/$kit"
