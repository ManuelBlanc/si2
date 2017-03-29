
# Commando usado para compilar el .tex
$pdflatex = 'pdflatex %O -interaction nonstopmode %S';

# Pone el resultado final en la carpeta out/
$out_dir = $aux_dir = 'out';

# Generamos solo un PDF
$pdf_mode = 1; $postscript_mode = $dvi_mode = 0;

# Abre un visor de PDF cuando termina de compilar
$preview_mode = 1;
$preview_continuous_mode = 0;

# Para que funcione el modo PVC bien
$pvc_view_file_via_temporary = 1;

# Para que se visualize el PDF y no el DVI o PS
$view = 'pdf';

# Algunas variables de entorno que usa pdflatex
$ENV{'TEXINPUTS'}       = '../latex:' . ($ENV{'TEXINPUTS'} // '');
$ENV{'max_print_line'}  = 1000; # Cualquier numero
$ENV{'error_line'}      = 254; # Maximo: 254
$ENV{'half_error_line'} = 238; # Maximo: error_line - 16
