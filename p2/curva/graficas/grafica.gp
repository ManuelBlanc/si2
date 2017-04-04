#!/usr/bin/env gnuplot

## Etiqueta, formato y estilo
set encoding utf8
set terminal png truecolor size 975, 525 # background rgb'gray80'
#set termoption font 'arial'
#set object 1 rectangle from 0,0 to 9999,9999 fillcolor rgb'gray100' behind

# Estilos
set style data     linespoints
set style function lines
#set key box top left
unset key

set style line 1 linecolor rgb'#0060ad' #cce8ff'
set style line 2 linecolor rgb'#dd181f' #fad1d2'
#set style fill transparent solid 0.25 noborder

# Eje X
set xlabel 'Usuarios (N)'
set xtics nomirror 1, 500, 2501
set xrange [1:2501]
set mxtics 4


# Eje Y
set ylabel 'Rendimiento (Hz)'
set grid ytics
set yrange [0:]

# Entrada
# set datafile separator ","

# Salida
set title 'Latencia vs usuarios'
set ylabel 'Latencia (s)'
set output 'graficas/latencia.png'
plot \
 	'datos/agregado.tab.dsv'	using 1:2 ls 1 notitle smooth sbezier	\
,	''                      	using 1:2 ls 1 notitle with points   	\
,	0/0                     	          ls 1 title 'ProcesaPago'   	\
,	'datos/agregado.tab.dsv'	using 1:5 ls 2 notitle smooth sbezier	\
,	''                      	using 1:5 ls 2 notitle with points   	\
,	0/0                     	          ls 2 title 'TOTAL'         	\


set title 'Throughput vs usuarios'
set ylabel 'Rendimiento (Hz)'
set output 'graficas/throughput.png'
plot \
 	'datos/agregado.tab.dsv'	using 1:4 ls 1 notitle smooth sbezier	\
,	''                      	using 1:4 ls 1 notitle with points   	\
,	0/0                     	          ls 1 title 'ProcesaPago'   	\
,	'datos/agregado.tab.dsv'	using 1:7 ls 2 notitle smooth sbezier	\
,	''                      	using 1:7 ls 2 notitle with points   	\
,	0/0                     	          ls 2 title 'TOTAL'         	\

