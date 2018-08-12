
source $HOME/bin/functions_bashrc.bash
source $HOME/bin/functions_graphics.bash
source $HOME/bin/functions_math.bash
source $HOME/bin/functions_scripting.bash

# This needs improvement
help-bash-functions(){
    for f in functions_*.bash; do
	egrep "*\(\)" $f | cut -d"{" -f1 > list.tmp
	cat list.tmp | \
	    while read line; do
	    grep -B20 "$line" $f | \
		tac | awk '{if ($0==""){exit} else {print}}' \
	    | tac
	    echo
	done
    done
}
