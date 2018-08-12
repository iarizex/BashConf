# math functions for bash scripting

# command line calculator (use square brackts to avoid bash confusion)
=() { 
    local in="$(echo "$@" | sed -e 's/\[/(/g' -e 's/\]/)/g')"
    # echo "in=$in"
    awk 'BEGIN {print '"$in"'}' < /dev/null
}

# command line calculator, output formatted to nr of digits
=2() {
    if [ "$#" -lt 2 ]; then
	echo "usage: =2 expression nr-of-digits" >&2; return 1
    fi
    awk 'BEGIN {printf "%.'$2'f\n", '"$1"'}' < /dev/null
}

# comand line calculator, %g output
=g() { 
    local in="$(echo "$@" | sed -e 's/\[/(/g' -e 's/\]/)/g')"
    # echo "in=$in"
    awk 'BEGIN {printf "%g\n", '"$in"'}' < /dev/null
}

# arccos
acos(){
    echo $1|awk -f ~/bin/acos.awk
}

# absolute value (float)
fabs() { 
    if [ $# -eq 0 ]; then
	awk '{if ($1<0) print -$1; else print $1}'
    else
	local a="$1"
	awk -v a=$a 'BEGIN {if (a<0) print -a; else print a}' < /dev/null
    fi
}

# Gas constant times temperature, given the temperature (default 298.15)
RT(){
    
    if [ "$1" == "" ]; then
	local T=298.15
	echo "Temperature not given, using $T K" >&2
    else
	local T=$1	
    fi    
    local rt=$(= "8.314472e-3*$T")
    echo "$rt"
}

# make a scatter plot from two time-vs-data files
# with -diag, plot the diagonal
scatter-plot(){
    if [[ ( $# != 2 ) && ( $# != 3 ) ]];then
	echo "Usage: scatter-plot [-diag] file1 file2" >&2; return 1;
    fi
    if [ "$1" = -diag ]; then
	local bDiag=1 
	shift
    else 
	local bDiag=0
    fi
    test -e "$1" || { echo "No such file \"$1\"" >&2; return 1; }
    test -e "$2" || { echo "No such file \"$2\"" >&2; return 1; }
    rmxvg "$1" | column 2 > scat.tmp1
    rmxvg "$2" | column 2 > scat.tmp2
    if [ $bDiag = 1 ]; then 
	local max=`cat scat.tmp1 scat.tmp2 | maxvalue_float`
	local min=`cat scat.tmp1 scat.tmp2 | minvalue_float`
	echo -e "$min $min\n$max $max\n&"
    fi   
    paste scat.tmp1 scat.tmp2 | awk 'NF==2'
    rm -f scat.tmp1 scat.tmp2
}

# round to a certain nr of digits
function round_ndig()
{
    awk '{printf "%.'$1'f\n", $1}'
}

# random number
# with parameter random ingeter in [0 max]
# without paramter, random number in [0 1]
function rand()
{
    if [ $# -gt 0 ]; then
	echo $(= "int(1.0*$RANDOM/32768*$1)")
    else
	echo $(= "1.0*$RANDOM/32768")
    fi
}

randf(){
    [ "$1" = "" ] && { echo Usage: randf MAXVALUE >&2; return 1; }
    = "1.0*$RANDOM/32768*$1"
}


# is integer even?
function is_even()
{
    [[ $(echo "$1%2"|bc) = 0 ]]
}

# is integer odd?
function is_odd()
{
    [[ $(echo "$1%2"|bc) = 1 ]]
}

# return norm of a vector sqrt(a^2+b^2+...)
function norm()
{
    local sum=0
    while [[ $# -gt 0 ]]; do
	sum=$(= "$sum+$1*$1")
	shift
    done
    sum=$(= "sqrt($sum)")
    echo $sum
}


# normalize a vector
function normalize()
{
    local norm=$(norm $@)
    local c
    while [[ $# -gt 0 ]]; do
	c=$(= "$1/$norm")
	echo -n "$c "
	shift
    done
    echo
}

# scalar product of two vectors.
# Default: 3 dimension, use -d DIM for different dimension
function sprod()
{
    local dim=3
    if [ "$1" = '-d' ]; then
	dim="$2"
	shift 2
    fi
    if [ $# -ne $[dim*2] ];then
	echo "Error, expected $[dim*2] parameters (after -d dim)" >&2; return 1
    fi
    local sum=0
    local tmp x y ind2
    for i in `seq 1 $dim`; do
	ind2=$[1+dim]
	eval x=$1
	eval y=\${$ind2}
	# echo i $i ind1 $ind1 ind2 $ind2 x $x y $y
	sum=$(= "$sum+$x*$y")
	shift 1
    done
    echo $sum
}

# scalar times vector
vec_mult()
{
    if [ $# -ne 4 ];then
	echo "Error, vec_mult requies 4 parameters" >&2; return 1
    fi
    local x=$(= "$1*($2)")
    local y=$(= "$1*($3)")
    local z=$(= "$1*($4)")
    echo "$x" "$y" "$z"
}

# difference betwen two vectors
vec_diff()
{
    if [ $# -ne 6 ];then
	echo "Error, vec_diff requies 6 parameters" >&2; return 1
    fi
    local dx=$(= "$1-($4)")
    local dy=$(= "$2-($5)")
    local dz=$(= "$3-($6)")
    echo "$dx" "$dy" "$dz"
}

# distance between two atoms
vec_dist(){
    if [ $# -ne 6 ];then
	echo "Error, vec_diff requies 6 parameters" >&2; return 1
    fi
    #echo vec_diff $@
    local diff=$(vec_diff $@)
    local norm=$(norm $diff)
    echo $norm
}

# sum of two vectors
vec_add()
{
    if [ $# -ne 6 ];then
	echo "Error, vec_diff requies 6 parameters" >&2; return 1
    fi
    local x=$(= "$1+($4)")
    local y=$(= "$2+($5)")
    local z=$(= "$3+($6)")
    echo "$x" "$y" "$z"
}

# angle between two vectors
vec_angle()
{
    local bDeg=0
    if [ "$1"  = -deg ];then
	bDeg=1
	shift
    fi
    if [ $# -ne 6 ];then
	echo "Error, vec_angle requies 6 parameters (after optional -deg)" >&2
	return 1
    fi
    local norm1=`norm $1 $2 $3`
    local norm2=`norm $4 $5 $6`
    local sprod=`sprod $1 $2 $3 $4 $5 $6`
    local cosang=`= "$sprod/($norm1*$norm2)"`
    local angle=`acos $cosang`
    if [ $bDeg = 1 ];then
	angle=`= $angle*180/3.1415926`
    fi
    echo $angle
}

# test if an expression is true allowing floats
# e.g. float_true "3.4>2"
function float_true()
{ 
    [[ $(echo "$1"|sed s/e/E/g|bc -l) == 1 ]] && return 0 || return 1
}

# sum a column (default: fist column, otherwise give the column nr)
sum_column() {
    local col=1
    [[ $# -gt 0 ]] && col=$1
    awk -v c=$col \
        'BEGIN{sum=0;}
         {sum+=$c}
         END{print sum} '
}

# average a column 
average_column(){
    local col=1
    [[ $# -gt 0 ]] && col=$1
    awk -v c=$col \
        'BEGIN{sum=0; n=0;}
         {sum+=$c; n++}
         END{printf "%6g\n", 1.0*sum/n} '
}
# root mean square of a column 
rootMeanSquare_column(){
    local col=1
    [[ $# -gt 0 ]] && col=$1
    awk -v c=$col \
        'BEGIN{sum=0; n=0;}
         {sum+=$c^2; n++}
         END{printf "%6g\n", sqrt(1.0*sum/n)} '
}
# root mean square of a column devided by sqrt(n)
# This is used to compute the error of an a average
errorOfAverage_column(){
    local col=1
    [[ $# -gt 0 ]] && col=$1
    awk -v c=$col \
        'BEGIN{sum=0; n=0;}
         {sum+=$c^2; n++}
         END{printf "%6g\n", sqrt(1.0*sum)/n} '
}


# Pearson correlation coefficient, given the
# two averages and sigmas
pearson_av_sig(){
    av1=$1
    av2=$2
    sig1=$3
    sig2=$4
    # echo "pearson_av $av1 $av2"
    awk -v av1=$av2   -v av2=$av2 \
	-v sig1=$sig1 -v sig2=$sig2 \
	'BEGIN{sum=0; n=0;}
         { sum+=($1-av1)*($2-av2); n++;}
         END{print 1.0*sum/(n*sig1*sig2)}'
}

# pearson correlation coefficient (R) between
# data in two files (times must be identical)
pearson(){
    cp $1 pearson.tmp1.xvg
    cp $2 pearson.tmp2.xvg
    
    rmxvg $1 > pearson.tmp1
    rmxvg $2 > pearson.tmp2
    g_analyze -f pearson.tmp1.xvg &> out.tmp || { cat out.tmp; return 1; }
    local av1=$(grep SS1 out.tmp | column 2)
    local sig1=$(grep SS1 out.tmp| column 3)
    g_analyze -f pearson.tmp2.xvg &> out.tmp || { cat out.tmp; return 1; }
    local av2=$(grep SS1 out.tmp | column 2)
    local sig2=$(grep SS1 out.tmp| column 3)
    echo "Averages: $av1 $av2, Stddevs: $sig1 $sig2" >&2
    paste pearson.tmp1 pearson.tmp2 | \
	awk '{print $2, $4}' > pearson.tmp3
    pearson_av_sig $av1 $av2 $sig1 $sig2 < pearson.tmp3
    rm -f pearson.tmp1.xvg pearson.tmp2.xvg pearson.tmp[0-3] out.tmp
}

# Pearson correlation (R) between first and second column
pearsonxy(){
    awk '{print NR, $1}' < $1 > pear1.tmp
    awk '{print NR, $2}' < $1 > pear2.tmp
    pearson pear1.tmp pear2.tmp
    rm -f pear1.tmp pear2.tmp
}

# plot an analytical function, write x-y to stdout
plotfunc(){
    local b=-1
    local e=1
    local f='x^2'
    local n=100
    while [ $# -gt 0 ]; do
	case "$1" in
	    -b ) shift
		b=$1 	;;
	    -e ) shift
		e=$1  ;;
	    -f ) shift
		f="$1" ;;
	    -n ) shift
		n=$1  ;;
	    *)
		echo Error, unknown argument: $1 >&2
		return 1;;
	esac
	shift
    done
    seq 0 $n | \
	awk -v b="$b" -v e="$e" -v n="$n" \
	'
         BEGIN {dx=(e-b)/n}
         {x=b+$1*dx
          print x,'"$f"'
         }'
}

# plot Ryckaert-Bellemans dihedral potential
plot-ryckaert-bellemans(){
    if [ $# -lt 6 ];then
	echo "usage: plot-ryckaert-bellemans C0 ... C5"; return 1
    fi
    local C0=$1
    local C1=$2
    local C2=$3
    local C3=$4
    local C4=$5
    local C5=$6
    local f="$C0*cos(x)^0 + $C1*cos(x)^1 + $C2*cos(x)^2"
    f="$f + $C3*cos(x)^3 + $C4*cos(x)^4 + $C5*cos(x)^5"
    plotfunc -b 0 -e 6.28318 -f "$f"
}

# average data columns (1st column = time)
average_data_line()
{
    awk '{sum=0;
          for (i=2; i<=NF; i++)
              { sum+=$i; }
          print $1, sum/(NF-1), sum, NF
        }'
}


# average numbers in a line
average_line(){
    local n=0
    local sum=0
    while [ $# -gt 0 ]; do
	let n++
	sum=$(= "$sum+($1)")
	shift
    done
    local av=$(= "$sum/$n")
    echo $av
}

# return lagest numrical value of a line (integers only)
maxvalue(){
    local max=$1
    shift
    while [ $# -gt 0 ]; do
	[ "$1" -gt $max ] && max="$1"
	shift
    done
    echo $max
}

# return smallest numrical value of a line (integers only)
minvalue(){
    local min=$1
    shift
    while [ $# -gt 0 ]; do
	[ "$1" -lt $min ] && min="$1"
	shift
    done
    echo $min
}

# return largest value (allowing floats) of a line/column
maxvalue_float(){
    awk 'BEGIN{max=-1e20}
    { for (i=1;i<=NF;i++)
        if ($i>max) max=$i }
         END{print max}'
}

# return smallest value (allowing floats) of a line/column
minvalue_float(){
    awk 'BEGIN{min=1e20}
    { for (i=1;i<=NF;i++)
        if ($i<min) min=$i }
         END{print min}'
}

# average over Y values with identical X values
average_identical_X(){
    sort -n -k 1 > tmptmp
    awk 'BEGIN{ bFirst=1; sum=0; n=0}
        { 
           #print bFirst
           if (bFirst==0 && $1!=last){
              print last, sum/n
              sum=$2
              n=1
           }
           else{
              sum += $2
              n++
              #printf "Now sum %f n %d\n", sum, n
           }
           bFirst=0
           last=$1    
        }
        END{print last, sum/n}' < tmptmp
}

# scalar product of two vectors in two trr files
trrvec_scalar_prod(){
    if [ $# -lt 2 ]; then
	echo "Usage: trrvec_scalar_prod trrfile1 trrfile2" >&2
	return 1
    fi
    local trr=( $1 $2 )
    local trr1=$1
    local trr2=$2
    
    for i in 1 2; do
	rm -f vectmp
	j=$[i-1]
	# echo trr = ${trr[j]} >&2
	gmxdump -f ${trr[j]} > vectmp 2> err.tmp || { cat err.tmp >&2; return 1; }
	nfr=$(grep -c "step=" vectmp)
	# echo nfr=$nfr >&2
	if [ $nfr = 3 ]; then
	    sed -n '/step=\ *1 /,/step=\ *2 /p' < vectmp | \
		egrep '^\ *x\[ ' | cut -d= -f2 | tr '{,}' ' ' > vec$i.tmp
	elif  [ $nfr = 2 ]; then
	    sed -n '/step=\ *0 /,$ p' < vectmp | \
		egrep '^\ *x\[ ' | cut -d= -f2 | tr '{,}' ' ' > vec$i.tmp
	else
	    echo "Error, there are not 2 or 3 vectors in the trr file ${trr[j]}" >&2
	    return 1
	fi
    done

    paste vec1.tmp vec2.tmp | \
	awk 'BEGIN{sum=0;}
             { sum += $1*$4 + $2*$5 + $3*$6; }
             END{print sum}
             '
    rm -f vectmp vec1.tmp vec2.tmp err.tmp
}

eval_variables(){
    local __input __s1 __s2 __b __builtinlist
    __input="$@"
    # first check for errors
    if echo "$__input" | perl -pe 's/\b[0-9][a-zA-Z]+/...ERROR.../g' | grep -q ERROR; then
	echo "Wrong input string: \"$__input\"" >&2; return 1
    fi    
    __builtinlist="int sqrt exp log sin cos atan2 rand srand"
    {
	echo 's/(\b[a-zA-Z]\w*)/(\$\1)/g;'
	for __b in $__builtinlist; do
	    echo 's/\(\$'${__b}'\)/'${__b}'/;'
	done
	echo 's/\(/\\\(/g;'
	echo 's/\)/\\\)/g;'
    } > replace.tmp.pl
    __s2=$(echo "$__input" | perl -p replace.tmp.pl)
    shopt -s -o nounset
    eval echo $__s2
    shopt -u -o nounset
}

=3(){
    local str str2
    str=$(eval_variables "$@") || { echo "Error in eval_variables, unbound variable or wrong string"; return 1; }
    str2=$(echo "$str" | sed -e 's/\[/(/g' -e 's/\]/)/g')
    echo "=3: Evaluating \`$str2'" >&2
    awk 'BEGIN {print '"$str2"'}' < /dev/null
}

# symmetrize a curve x, f(x) around x=0
symmetrize_around_zero(){
    awk '
function floor(x){
    if (x>=0)
	floorx=int(x)
    else
	floorx=int(x)-1
    return floorx
}

BEGIN{i=0}
{
    z[i]=$1
    y[i]=$2
    i++
}
END{
    bins=i
    dz=z[1]-z[0]
    min=z[0]

    for (i=0; i<bins; i++){
        zsym=-z[i];
        # bin left of zsym
        j=floor((zsym-min)/dz);
        if (j>=0 && (j+1)<bins)
        {
            # interpolate profile linearly between bins j and j+1
            z1=min+j*dz;
            deltaz=zsym-z1;
            ysym=y[j] + (y[j+1]-y[j])/dz*deltaz;
            # average between left and right 
            y2[i]=0.5*(ysym+y[i]);
        }
        else
        {
            y2[i]=y[i];
        }
    }
    for (i=0; i<bins; i++)
	print z[i], y2[i]
}
'
}
