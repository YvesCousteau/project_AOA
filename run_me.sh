#!/bin/bash

let SSE_AVX=0
let COUNT=$(ls -d */ | sed '/^syst*/d' | sed '/^plot/d' | wc -w)
let TMP=0
let RED=41
let BLACK=0
let YELLOW=43
let ALT=0


progressbar()
{
    bar="##################################################"
    size_bar=${#bar}
    percent_actual=$(( (($1*100)/COUNT) ))
    size_actual=$(( ((percent_actual*size_bar)/100) ))
    printf "\r[\e[${RED}m%-${size_bar}s \e[${YELLOW}m(%d%%)\e[${BLACK}m] \n" "${bar:0:size_actual}" "$percent_actual"
}

benchmark()
{
  TMP=0
  for i in $(ls -d */ | sed '/^syst*/d' | sed '/^plot/d');
  do
      ((TMP = TMP + 1))
      cd $i
      SSE_AVX=$(find . -type f -name '*_SSE*')
      taskset -c 3 $SSE_AVX $(( ${1} * 2**10 )) 1000 | cut -d';' -f1,9 > load_${2}.dat
      if [ $i = "pc/" ] || [ $i = "memcpy/" ]
      then
        ALT=$(cat load_$2.dat | sed '2,34!d' | cut -d"," -f 1,4)
        echo "$ALT" > load_${2}.dat
      fi
      chart $2
      progressbar $TMP
      cd ..
  done
  echo "All $OPTION data benchmark (1K loop) completed & All $OPTION charts created"
}

chart()
{

  gnuplot <<-EOF > ../plot/$1/"${PWD##*/}_${1}.png"
set term png size 1900,1000 enhanced font "Terminal,10"
set grid
set auto x
set key left top
set title "Intel i7-10750H+ bandwidth (in GiB/s) for a ${PWD##*/} benchmark on a single array"
set xlabel "Benchmark variants"
set ylabel "Bandwidth in GiB/s (higher is better)
set style data histogram
set style fill solid border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set multiplot layout 2, 2 rowsfirst
set autoscale y
set title "${PWD##*/} ${1} cache"
plot "load_${1}.dat" u 2:xtic(1) t "Intel i7-10750H"
unset multiplot
EOF
}


echo "Let's go in my project"
while :
do
  echo "Menu :"
  echo "1 : Compilation files C"
  echo "2 : Benchmark L1"
  echo "3 : Benchmark L2"
  echo "4 : Benchmark L3"
  echo "5 : Benchmark All"
  echo "0 : Exit"
  read INPUT_STRING
  case $INPUT_STRING in
	1)
    for i in $(ls -d */ | sed '/^syst*/d');
    do
        cd $i/ ; make clean ; cd ..
        cd $i/ ; make ; cd ..
    done
    clear
		echo "Compilation completed"
		;;
  2)
    OPTION="L1"
    CACHE_SIZE=30
    benchmark $CACHE_SIZE $OPTION
    ;;
  3)
    OPTION="L2"
    CACHE_SIZE=200
    benchmark $CACHE_SIZE $OPTION
    ;;
  4)
    OPTION="L3"
    CACHE_SIZE=1200
    benchmark $CACHE_SIZE $OPTION
    ;;
  5)
    OPTION="L1"
    CACHE_SIZE=30
    benchmark $CACHE_SIZE $OPTION

    OPTION="L2"
    CACHE_SIZE=200
    benchmark $CACHE_SIZE $OPTION

    OPTION="L3"
    CACHE_SIZE=1200
    benchmark $CACHE_SIZE $OPTION
    ;;
	0)
		echo "See you again!"
		break
		;;
	*)
		echo "Sorry, I don't understand"
		;;
  esac
done

echo "That's all folks!"


#sed '2,34!d' load_L1.dat | cut -d"," -f 4
