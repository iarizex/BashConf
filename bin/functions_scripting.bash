# A collection of useful functions for scripting
bash_error_func()
{
    {
	echo -e "\n+++ ERROR +++ ERROR +++ ERROR +++"
	echo -e "Line $1, script `basename $2`\n"
	echo -e "$3"
	echo -e   "+++++++++++++++++++++++++++++++++\n"
    } >&2
    exit 192
}
bash_warning_func()
{
    {
	echo -e "\n++++++++++++ WARNING ++++++++++++++"
	echo -e "Line $1, script `basename $2`\n"
	echo -e "$3"
	echo -e   "+++++++++++++++++++++++++++++++++\n"
    } >&2
}
# otherwise this alias is not expanded in my script.
shopt -s expand_aliases
alias bash_error='bash_error_func $LINENO $0'
alias bash_warning='bash_warning_func $LINENO $0; return 192'

bash_try()
{
    local cmd=echo err=err.tmp bKeep=0
    while [ $# -gt 0 ]; do
	case "$1" in
            -c) shift
		cmd="$1" ;;
            -e) shift
		err="$1" ;;
	    -keep) 
		bKeep=1 ;;
	    * )
		echo -e "\nError in bash_try, unknown argument: $1"; exit 1 ;;
	esac
	shift
    done
    $cmd >& $err
    if [ $? -ne 0 ]; then
	{
	    echo -e "\n+++ ERROR +++ ERROR +++ ERROR +++++ - This command created an error:\n"
	    echo -e "$cmd\n"
	    echo -e   "+++++++++++++++++++++++++++++++++"
	    echo -e "Output:\n"
	    cat $err 
	} >&2
	exit 1
    else 
	[ $bKeep = 0 ] && rm -f $err
    fi   
}

# Good to run some jobs in parallel:
# sleep while more or equal to n jobs are running
# NOT SURE IF THAT WORKS AS IT SHOULD, CHECK JOBS CAREFULLY
wait2(){
    local jobname n sec njobs v
    v=0; sec=3; n=1; jobname=xxxxx
    while [ $# -gt 0 ]; do
	case "$1" in
            -j ) shift
		jobname="$1" ;;
            -n) shift
		n="$1" ;;
            -sec) shift
		sec="$1" ;;
            -v)
		v=1 ;;
            * )
		echo -e "\nError in wait2, unknown argument: $1"; exit 192 ;;
	esac
	shift
    done
    njobs=100000
    while [ $njobs -ge $n ]; do
	# may not have pgrep on a Mac, use poor man's pgrep
	njobs=$(ps aux | grep ^$USER | grep -v grep | grep -c "$jobname")
	if [ $njobs -ge $n ]; then
	    [ $v = 1 ] && \
		echo "Found $njobs $jobname running, allowing $n, sleep $sec sec"
	    sleep $sec
	fi
    done
}

# return full path of file - use php realpath()
lsd()
{
    while [ $# -gt 0 ]; do
	if which php >& /dev/null; then
	    eval "expand_tild=$1"
	    php  -r "echo realpath('$expand_tild');"
	    echo
	else
	    echo "$PWD"/"$1"
	fi
	shift
    done
}


# return file extension
fileext()
{
    if [ $# -gt 0 ]; then
	echo "$1" | awk -F. '{print $NF}'
    else
	awk -F. '{print $NF}'
    fi
}

# cat for zipped files
cat-zip(){
    local ext=$(echo $1 | awk -F. '{print $NF}')
    case $ext in
	gz)
	    gzip -c $1 ;;
	bz2) 
	    bunzip2 -c $1 ;;
	zip)
	    unzip2 -c $1 ;;
	*)
	    cat $1 ;;
    esac
}

# paste a very large number of files next to each other
# This allows more files than the normal paste command
paste-many(){
    files="$1"
    test -e "$files" || { echo "No such file $files" >&2; return 1; }
    local N=200
    local n=$(wc -l < $1)
    local imin=1
    local imax=$[imin+N-1]
    local i=0
    while [ $imin -le $n ]; do
	files1=$(fromto $imin $imax < "$files" | tr '\n' ' ')
	echo "files1 = $files1" >&2
	tmp[$i]=$(mktemp `pwd`/tmp.XXXXXXXXXXXX) || return 1
	paste -d ' ' $files1 > ${tmp[$i]} || return 1
	let imin+=$N
	let imax+=$N
	let i++
    done
    paste ${tmp[@]}
    rm -f ${tmp[@]}
}

# remve comments and formting stuff (and &) from xmgrace file
rmxvg(){
    if [ $# = 1 ];then
	test -e "$1" || { echo "ERROR in rmxvg: No such file \"$1\"" >&2; return 1; }
	egrep -v '#|@|&' $1
    else
	egrep -v '#|@|&'
    fi
}

# turn grace agr file into a template, that is get formatting info
agr2template(){
    if [ $# -eq 1 ] ;then
	sed '/@target G0.S0/,$ d' < $1 | sed '/@type xy/,$ d' \
	    > ${1}-templ
	echo Created ${1}-templ >&2
    else
	sed '/@target G0.S0/,$ d' < $1 | sed '/@type xy/,$ d' > $2
	echo Created $2
    fi
}

# get time step from grace file (from first column)
xvg_timestep(){
    test -e "$1" || { echo "ERROR in xvg_timestep: No such file \"$1\"" >&2; return 1; }
    local t12=$(rmxvg "$1" | head -2 | column 1 | tr '\n' ' ')
    echo "$t12" | awk '{print ($2)-($1)}'
}

# print only every ith line of a file
write_every_x(){
    if [ "$1" == "" ]; then
	echo "Usage: $0 n [file]" >&2; return 1
    fi
    local x="$1"
    shift
    if [ $# = 1 ]; then
	test -e "$1" || { echo "No such file: $1"; return 1; }
	awk '((NR%'$x')==1) {print $0}' < $1
    else
	awk '((NR%'$x')==1) {print $0}' 
    fi
}

# print a column
column(){ awk '{print $'$1'}'; }

# give number of columns
ncolumns(){  awk '{print NF}'; }

# trimming a line (remove whitespace)
triml(){ perl -pe 's/^\s+//'; }
trimr(){ perl -pe 's/\s+\n$/\n/'; }
trimlr(){ triml | trimr; }
rm-time-column(){
    triml | perl -pe 's/^[\w,\.]+\s//g'
}
trim-multi-whitespace(){
    tr "\t" " " | tr -s " "
}

# print file from line x until y
fromto()
{
    if [ $# -lt 2 ]; then
	echo "Usage: fromto startline endline" >&2; return 1
    fi
    if [ $1 -lt 1 ]; then
	echo "Error in fromto, first argument is $1". >&2; exit 1
    fi
    local len=$[$2-$1+1]
    tail -n +$1 | head -n $len
}

# print a command line and execute it afterwords
do_and_print()
{
    local bV=0
    if [ $# -gt 0 ];then
	if [ $1 = "-v" ];then
	    bV=1
	    shift
	fi
    fi
    echo "$@"
    if [ $bV = 1 ]; then
	$@
    else
	$@ >& err.tmp || { cat err.tmp >&2; return 1; }
    fi
}

# verbose mkdir, allowing multiple dirs
mkdir-multi() 
{
    local v=""
    if [[ "$1" == "-v" ]] ; then
	v=v
	shift
    fi
    while [ $# -gt 0 ]; do
	local dir="$1"
	shift
	test -d $dir && continue
	mkdir -p$v $dir || {
	    echo -e "\nERROR --- Cannot create directory $dir ---\n" >&2
	    return 1
	}
	echo "Created $dir"
    done
    return 0
}

# print variables and their value, allowing multiple arguments
printVariables(){
    [ "$1" = "-n" ] && { bNewLine=0; shift; } || bNewLine=1
    if [ $bNewLine = 1 ]; then
	while [ $# -gt 0 ]; do
            eval echo $1=\"\$$1\"
            shift
	done
    else	
	while [ $# -gt 0 ]; do
            eval echo -n $1=\"\$$1 \"
            shift
	done
	echo
    fi
}

# print a interger using a certain nr of digits, adds zeros to the front
# e.g. print_ndig 3 2 gives 002
function print_ndig()
{
    printf "%0${2}d\n" "$1"
}

# check if a list of files is present, otherwise return 1
# an write warning.
files-present(){
    while [ $# -gt 0 ]; do
	if ! test -e "$1"; then
	    echo "No such file '${1}'" >&2; return 1
	fi
	shift
    done
    return 0
}


# print header with # and @ of xvg/agr file
xvg_header(){
    awk '{key=substr($0,0,1); if (key=="#" || key=="@") print; else exit; }' $1
}

# concatenate several xvg files (overlapping times are removed)
concat_xvgs(){
    local n=$# lasttime ncol
    
    ncol=$(rmxvg $1 | head -n 1| ncolumns)
    echo "ncol = $ncol" >&2
    xvg_header $1
    cat $1 | awk 'NF=='$ncol
    while [ $# -ge 2 ]; do
	lasttime=$(tail $1 | awk 'NF=='$ncol | tail -n 1 | column 1)
	rmxvg $2 | awk -v tmin=$lasttime -v ncol=$ncol \
	    '$1>tmin && NF==ncol'
	shift
    done
}

findsource(){
    local pat=$1
    shift
    while [ $# -gt 0 ]; do
	pat="$pat|$1"
	shift
    done
    echo "pat=$pat"
    find . -name "*.[hc]" -exec egrep "$pat" {} \; -print
}
