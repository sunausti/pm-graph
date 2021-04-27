#!/bin/sh

CMD="../sleepgraph.py"
HOST=`hostname`
CLEANUP=1
MODES=""

printhelp() {
	echo "USAGE: testall.sh [-h/-s/-f/-m]"
	echo "OPTIONS"
	echo "   -h: print help"
	echo "   -s: save output files after test"
	echo "   -f: test the freeze functionality"
	echo "   -m: test the mem functionality"
}

while [ "$1" ] ; do
	case "$1" in
		-h)
			shift
			printhelp
			exit
		;;
		-s)
			shift
			CLEANUP=0
		;;
		-f)
			shift
			MODES="$MODES freeze"
		;;
		-m)
			shift
			MODES="$MODES mem"
		;;
		*)
			echo "Unknown option: $1"
			printhelp
			exit
		;;
	esac
done

check() {
	if [ $? -ne 0 ]; then
		echo "FAIL -> $1"
		exit
	fi
	if [ -z "$1" ]; then
		echo "PASS"
	else
		FAIL=0
		while [ "$1" ] ; do
			if [ ! -e "$1" -o ! -s "$1" ]; then
				FAIL=1
				break
			fi
			shift
		done
		if [ $FAIL -eq 0 ]; then
			echo "PASS"
		else
			echo "FAIL -> $1"
			exit
		fi
	fi
}

OUTDIR=`mktemp -d`

# one-off commands that require no suspend

echo -n "HELP TEST: "
$CMD -h > $OUTDIR/help.txt
check $OUTDIR/help.txt

echo -n "VERSION TEST: "
$CMD -v > $OUTDIR/version.txt
check $OUTDIR/version.txt

echo -n "MODES TEST: "
$CMD -modes > $OUTDIR/modes.txt
check $OUTDIR/modes.txt

echo -n "STATUS TEST: "
$CMD -status > $OUTDIR/status.txt
check $OUTDIR/status.txt

echo -n "SYSINFO TEST: "
sudo $CMD -v > $OUTDIR/sysinfo.txt
check $OUTDIR/sysinfo.txt

echo -n "DEVINFO TEST: "
$CMD -devinfo > $OUTDIR/devinfo.txt
check $OUTDIR/devinfo.txt

echo -n "CMDINFO TEST: "
$CMD -cmdinfo > $OUTDIR/cmdinfo.txt
check $OUTDIR/cmdinfo.txt

echo -n "WIFICHECK TEST: "
$CMD -wificheck > $OUTDIR/wifi.txt
check $OUTDIR/wifi.txt

echo -n "FPDT TEST: "
sudo $CMD -fpdt > $OUTDIR/fpdt.txt
check $OUTDIR/fpdt.txt

echo -n "FLIST TEST: "
sudo $CMD -flist > $OUTDIR/flist.txt
check $OUTDIR/flist.txt

echo -n "FLISTALL TEST: "
sudo $CMD -flistall > $OUTDIR/flistall.txt
check $OUTDIR/flistall.txt

echo -n "FPDT TEST: "
sudo $CMD -fpdt > $OUTDIR/fpdt.txt
check $OUTDIR/fpdt.txt

echo -n "DISPLAY TEST: "
$CMD -xstat > $OUTDIR/display.txt
check $OUTDIR/display.txt

# suspend dependent commands

for m in $MODES; do

	ARGS="-m $m -gzip -rtcwake 10 -verbose -addlogs -srgap -wifi -sync -rs off -display off -mindev 1"
	DMESG=${HOST}_${m}_dmesg.txt.gz
	FTRACE=${HOST}_${m}_ftrace.txt.gz
	HTML=${HOST}_${m}.html
	RESULT=result.txt

	echo -n "SIMPLE $m TEST: "
	OUT=$OUTDIR/suspend-${m}-simple
	sudo $CMD $ARGS -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "DEV $m TEST: "
	OUT=$OUTDIR/suspend-${m}-dev
	sudo $CMD $ARGS -dev -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "PROC $m TEST: "
	OUT=$OUTDIR/suspend-${m}-proc
	sudo $CMD $ARGS -proc -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "DEVPROC $m TEST: "
	OUT=$OUTDIR/suspend-${m}-devproc
	sudo $CMD $ARGS -dev -proc -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "X2 $m TEST: "
	OUT=$OUTDIR/suspend-${m}-x2
	sudo $CMD $ARGS -x2 -x2delay 100 -predelay 100 -postdelay 100 -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "CALLGRAPH $m TEST: "
	OUT=$OUTDIR/suspend-${m}-cg
	sudo $CMD $ARGS -f -maxdepth 10 -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "CALLGRAPHTOP $m TEST: "
	OUT=$OUTDIR/suspend-${m}-cgtop
	sudo $CMD $ARGS -ftop -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$DMESG $OUT/$FTRACE $OUT/$HTML $OUT/$RESULT

	echo -n "MULTI $m TEST: "
	OUT=$OUTDIR/suspend-${m}-x3
	sudo $CMD $ARGS -multi 3 0 -maxfail 1 -result $OUT/$RESULT -o $OUT > $OUT.txt
	check $OUT.txt $OUT/$RESULT $OUT/summary.html $OUT/summary-devices.html $OUT/summary-issues.html

done

if [ $CLEANUP -eq 0 ]; then
	echo "OUTPUT: $OUTDIR"
else
	rm -r $OUTDIR
fi
