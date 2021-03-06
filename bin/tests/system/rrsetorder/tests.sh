#!/bin/sh
#
# Copyright (C) 2006-2008, 2011, 2012, 2014-2016  Internet Systems Consortium, Inc. ("ISC")
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh

DIGOPTS="+nosea +nocomm +nocmd +noquest +noadd +noauth +nocomm +nostat +short +nocookie"
DIGCMD="$DIG $DIGOPTS -p 5300"

status=0

if grep "^#define DNS_RDATASET_FIXED" $TOP/config.h > /dev/null 2>&1 ; then
        test_fixed=true
else
        echo "I: Order 'fixed' disabled at compile time"
        test_fixed=false
fi

#
#
#
if $test_fixed; then
    echo "I: Checking order fixed (master)"
    ret=0
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
    do
    $DIGCMD @10.53.0.1 fixed.example > dig.out.fixed || ret=1
    cmp -s dig.out.fixed dig.out.fixed.good || ret=1
    done
    if [ $ret != 0 ]; then echo "I:failed"; fi
    status=`expr $status + $ret`
else
    echo "I: Checking order fixed behaves as cyclic when disabled (master)"
    ret=0
    matches=0
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
    do
        j=`expr $i % 4`
	$DIGCMD @10.53.0.1 fixed.example > dig.out.fixed  || ret=1
        if [ $i -le 4 ]; then
            cp dig.out.fixed dig.out.$j
        else
            cmp -s dig.out.fixed dig.out.$j && matches=`expr $matches + 1`
        fi
    done
    cmp -s dig.out.0 dig.out.1 && ret=1
    cmp -s dig.out.0 dig.out.2 && ret=1
    cmp -s dig.out.0 dig.out.3 && ret=1
    cmp -s dig.out.1 dig.out.2 && ret=1
    cmp -s dig.out.1 dig.out.3 && ret=1
    cmp -s dig.out.2 dig.out.3 && ret=1
    if [ $matches -ne 16 ]; then ret=1; fi
    if [ $ret != 0 ]; then echo "I:failed"; fi
    status=`expr $status + $ret`
fi

#
#
#
echo "I: Checking order cyclic (master + additional)"
ret=0
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.1 cyclic.example > dig.out.cyclic || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic dig.out.$j
    else
        cmp -s dig.out.cyclic dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

#
#
#
echo "I: Checking order cyclic (master)"
ret=0
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.1 cyclic2.example > dig.out.cyclic2 || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic2 dig.out.$j
    else
        cmp -s dig.out.cyclic2 dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`
echo "I: Checking order random (master)"
ret=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
	eval match$i=0
done
for i in a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 9
do
	$DIGCMD @10.53.0.1 random.example > dig.out.random || ret=1
	match=0
	for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
	do
		eval "cmp -s dig.out.random dig.out.random.good$j && match$j=1 match=1"
		if [ $match -eq 1 ]; then break; fi
	done
	if [ $match -eq 0 ]; then ret=1; fi
done
match=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
	eval "match=\`expr \$match + \$match$i\`"
done
echo "I: Random selection return $match of 24 possible orders in 36 samples"
if [ $match -lt 8 ]; then echo ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

#
#
#
if $test_fixed; then
    echo "I: Checking order fixed (slave)"
    ret=0
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
    do
    $DIGCMD @10.53.0.2 fixed.example > dig.out.fixed || ret=1
    cmp -s dig.out.fixed dig.out.fixed.good || ret=1
    done
    if [ $ret != 0 ]; then echo "I:failed"; fi
    status=`expr $status + $ret`
fi

#
#
#
echo "I: Checking order cyclic (slave + additional)"
ret=0
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.2 cyclic.example > dig.out.cyclic || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic dig.out.$j
    else
        cmp -s dig.out.cyclic dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

#
#
#
echo "I: Checking order cyclic (slave)"
ret=0
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.2 cyclic2.example > dig.out.cyclic2 || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic2 dig.out.$j
    else
        cmp -s dig.out.cyclic2 dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I: Checking order random (slave)"
ret=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
	eval match$i=0
done
for i in a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 9
do
$DIGCMD @10.53.0.2 random.example > dig.out.random || ret=1
	match=0
	for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
	do
		eval "cmp -s dig.out.random dig.out.random.good$j && match$j=1 match=1"
		if [ $match -eq 1 ]; then break; fi
	done
	if [ $match -eq 0 ]; then ret=1; fi
done
match=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
eval "match=\`expr \$match + \$match$i\`"
done
echo "I: Random selection return $match of 24 possible orders in 36 samples"
if [ $match -lt 8 ]; then echo ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I: Shutting down slave"

(cd ..; $SHELL stop.sh rrsetorder ns2 )

echo "I: Checking for slave's on disk copy of zone"

if [ ! -f ns2/root.bk ]
then
	echo "I:failed";
	status=`expr $status + 1`
fi

echo "I: Re-starting slave"

(cd ..; $SHELL start.sh --noclean rrsetorder ns2 )

#
#
#
if $test_fixed; then
    echo "I: Checking order fixed (slave loaded from disk)"
    ret=0
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
    do
    $DIGCMD @10.53.0.2 fixed.example > dig.out.fixed || ret=1
    cmp -s dig.out.fixed dig.out.fixed.good || ret=1
    done
    if [ $ret != 0 ]; then echo "I:failed"; fi
    status=`expr $status + $ret`
fi

#
#
#
echo "I: Checking order cyclic (slave + additional, loaded from disk)"
ret=0
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.2 cyclic.example > dig.out.cyclic || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic dig.out.$j
    else
        cmp -s dig.out.cyclic dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

#
#
#
echo "I: Checking order cyclic (slave loaded from disk)"
ret=0
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.2 cyclic2.example > dig.out.cyclic2 || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic2 dig.out.$j
    else
        cmp -s dig.out.cyclic2 dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I: Checking order random (slave loaded from disk)"
ret=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
	eval match$i=0
done
for i in a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 9
do
	$DIGCMD @10.53.0.2 random.example > dig.out.random || ret=1
	match=0
	for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
	do
		eval "cmp -s dig.out.random dig.out.random.good$j && match$j=1 match=1"
		if [ $match -eq 1 ]; then break; fi
	done
	if [ $match -eq 0 ]; then ret=1; fi
done
match=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
eval "match=\`expr \$match + \$match$i\`"
done
echo "I: Random selection return $match of 24 possible orders in 36 samples"
if [ $match -lt 8 ]; then echo ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

#
#
#
if $test_fixed; then
    echo "I: Checking order fixed (cache)"
    ret=0
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
    do
    $DIGCMD @10.53.0.3 fixed.example > dig.out.fixed || ret=1
    cmp -s dig.out.fixed dig.out.fixed.good || ret=1
    done
    if [ $ret != 0 ]; then echo "I:failed"; fi
    status=`expr $status + $ret`
fi

#
#
#
echo "I: Checking order cyclic (cache + additional)"
ret=0
# prime acache
$DIGCMD @10.53.0.3 cyclic.example > dig.out.cyclic || ret=1
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.3 cyclic.example > dig.out.cyclic || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic dig.out.$j
    else
        cmp -s dig.out.cyclic dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

#
#
#
echo "I: Checking order cyclic (cache)"
ret=0
# prime acache
$DIGCMD @10.53.0.3 cyclic2.example > dig.out.cyclic2 || ret=1
matches=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
    j=`expr $i % 4`
    $DIGCMD @10.53.0.3 cyclic2.example > dig.out.cyclic2 || ret=1
    if [ $i -le 4 ]; then
        cp dig.out.cyclic2 dig.out.$j
    else
        cmp -s dig.out.cyclic2 dig.out.$j && matches=`expr $matches + 1`
    fi
done
cmp -s dig.out.0 dig.out.1 && ret=1
cmp -s dig.out.0 dig.out.2 && ret=1
cmp -s dig.out.0 dig.out.3 && ret=1
cmp -s dig.out.1 dig.out.2 && ret=1
cmp -s dig.out.1 dig.out.3 && ret=1
cmp -s dig.out.2 dig.out.3 && ret=1
if [ $matches -ne 16 ]; then ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I: Checking order random (cache)"
ret=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
	eval match$i=0
done
for i in a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 9
do
	$DIGCMD @10.53.0.3 random.example > dig.out.random || ret=1
	match=0
	for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
	do
		eval "cmp -s dig.out.random dig.out.random.good$j && match$j=1 match=1"
		if [ $match -eq 1 ]; then break; fi
	done
	if [ $match -eq 0 ]; then ret=1; fi
done
match=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
eval "match=\`expr \$match + \$match$i\`"
done
echo "I: Random selection return $match of 24 possible orders in 36 samples"
if [ $match -lt 8 ]; then echo ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi

echo "I: Checking default order no match in rrset-order (random)"
ret=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
	eval match$i=0
done
for i in a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 9
do
$DIG +nosea +nocomm +nocmd +noquest +noadd +noauth +nocomm +nostat +short \
	-p 5300 @10.53.0.4 random.example > dig.out.random|| ret=1
	match=0
	for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
	do
		eval "cmp -s dig.out.random dig.out.random.good$j && match$j=1 match=1"
		if [ $match -eq 1 ]; then break; fi
	done
	if [ $match -eq 0 ]; then ret=1; fi
done
match=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
do
eval "match=\`expr \$match + \$match$i\`"
done
echo "I: Random selection return $match of 24 possible orders in 36 samples"
if [ $match -lt 8 ]; then echo ret=1; fi
if [ $ret != 0 ]; then echo "I:failed"; fi

status=`expr $status + $ret`
echo "I:exit status: $status"
[ $status -eq 0 ] || exit 1
