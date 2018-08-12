# functions for image manipulations

# resize am image. Keep number of pixels, just change the size in cm
resize_image(){
    if [ $# -lt 3 ];then
	echo "Usage: resize-image in new-width[cm] out [convert-options]"
	return 1
    fi
    
    in="$1"
    width="$2"
    out="$3"
    local opt="$4"
    test -e "$1" || { echo "No such file $1" >&2; return 1; }

    dpcm=$(identify -format "%x" $1 | column 1)
    w=$(identify -format "%W " $1)
    wcm=$(= "$w/$dpcm")
    dpcmNew=$(= "$dpcm*$wcm/$width")

    echo "Old dots per cm: $dpcm, new $dpcmNew" >&2
    echo "convert -units PixelsPerCentimeter -density ${dpcmNew}x${dpcmNew} $opt $1 $3"
    convert -units PixelsPerCentimeter -density ${dpcmNew}x${dpcmNew} $opt $1 $3
}

image_size(){
    local dpcm dummy w h
    # identify -format "%x %W %H" $1
    if [ ! -e "$1" ]; then
	echo "Usage: image-size image"; return 1
    fi
    identify -format "%x %W %H" $1 | read dpcm dummy w h
    # read dpcm dummy w h < <(identify -format "%x %W %H" $1)
    # identify -format "%x %W %H" $1 | read dpcm dummy w h
    echo $dpcm $dummy $w $h
    echo "$w x $h pixels"
    wcm=$(= "$w/$dpcm")
    hcm=$(= "$h/$dpcm")
    echo "$wcm x $hcm cm"   
}

# Set offsets of image page to zero
# this is helpful if some automatically merged pdf looks weired
# due to page offsets
figure_offsets_to_zero(){
    local in=$1
    [ $# -eq 2 ] && out=$2 || out=$in
    local H=$(identify -format "%H" $1)
    local W=$(identify -format "%W" $1)
    echo "convert $in -page ${W}x${H}+0+0 $out "
    convert $in -page ${W}x${H}+0+0 $out    
}

# put white frame (given in pixels) around image
whiteframe(){
    if [ $# -lt 3 ]; then
	echo "Usage: whiteframe -fr 20x20 picture [out]" >&2; return 1; 
    fi
    local in="$3"
    local fr="$2"
    [ $# -eq 4 ] && local out="$4" || local out="$in"
    echo "convert $in -background white -layers flatten -mattecolor white -frame $fr $out ..."
    convert $in -background white -layers flatten \
	-mattecolor white -frame $fr $out
}

# put a white frame around an image
whiteframe_mm(){
    if [ $# -lt 3 ];then
	echo "Usage: resize-image in framewidth[mm] out"
	return 1
    fi

    in="$1"

    dpcm=$(identify -format "%x" $1 | column 1)
    fr=$(= "$dpcm*$2/10")
    echo "convert $1 -background white -layers flatten -trim -mattecolor white -frame ${fr}x${fr} $3" >&2
    convert $1 -background white -layers flatten -trim -mattecolor white -frame ${fr}x${fr} $3
}

# trim all images in command line (remove e.g. white space around the image)
trim () 
{ 
    while test ! -z "$1"; do
        convert -trim $1 $1
        shift
    done
}

# scalable vector graphics to png (using inkscape)
svg2png(){
    local d=100
    if [ "$1" = -d ]; then
	d=$2
	shift 2
    fi
    local in="$1"
    test -e "$in" || { echo "No such file '$in'" >&2; return 1; }
    echo -e "Executing command:\n/Applications/Inkscape.app/Contents/MacOS/Inkscape $in --export-png=${in%%svg}png --export-dpi=$d --export-area-drawing\n"
    /Applications/Inkscape.app/Contents/MacOS/Inkscape $in --export-png=${in%%svg}png \
	--export-dpi=$d --export-area-drawing
}

# xmgrace file agr to eps
agr2eps(){ 
           local agr="$1"
	   local xmgrace=gracebat
	   if ! which gracebat &> /dev/null; then
	       xmgrace=xmgrace
	   fi
           test -e "$agr" || { echo "No such file: $agr"; return 1; }   
           $xmgrace -hdevice EPS -hardcopy $agr
}
agr2pdf(){
    while [ $# -gt 0 ]; do
	agr2eps $1
	local out=${1%%.agr}
	out=${out%%.xvg}
	epstopdf $out.eps
	rm -f $out.eps
	shift
    done
}

# eps to png. Use: eps2png [-d resolution] file.eps
eps2png(){
    local d=100
    if [ "$1" = -d ]; then
	d=$2
	shift 2
    fi
    local in="$1"
    test -e "$in" || { echo "No such file '$in'" >&2; return 1; }
    echo "convert -density $d $in ${in%%.eps}.png" ...
    convert -density $d $in ${in%%.eps}.png
}

# agr to png
agr2png(){
    local d=100
    if [ "$1" = -d ]; then
	d=$2
	shift 2
    fi
    while [ $# -gt 0 ]; do
	agr2eps $1
	local base=$(echo $1 | sed -e 's/\.xvg//' -e 's/\.agr//')
	eps2png -d $d $base.eps
	rm -fv $base.eps
	shift
    done
}

# make white pixels transparent
white2transparent(){
    convert -transparent white $1 $1
}

# add a color definition to a grace file (xvg or agr)
add_color_to_grace(){
    if [ $# -ne 5 ];then
	echo "Usage: add-color-to-grace agr-file colorname red green blue" >&2
	return 1
    fi
    local in="$1"
    local c=$2
    local r=$3
    local g=$4
    local b=$5

    last=$(grep '@map color ' "$in" | tail -n1|column 3)
    let next=$last+1
    local line="@map color $next to ($r, $g, $b), \"$c\""
    {
	echo "/@map color $last/ a\\"
	echo "@map color $next to ($r, $g, $b), \"$c\"" 
    } > add-color-to-grace.tmp    
    cat $in | sed -f add-color-to-grace.tmp
    # rm -f add-color-to-grace.tmp
}

agr-swap-xy(){
    awk '
    {
     a=substr($0,0,1)
     if (a=="@" || a=="#" || a=="&")
        print $0
     else
        print $2,$1
    }'

}
