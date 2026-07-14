/* cap input rows for the captured run */
options obs=100;

/* Mock stand-in for /tmp/model_metrics_DrinkGlas.csv: the per-epoch CNN
   training metrics the plotting script imports. In the repo these come from
   PROC IMPORT of the model's metrics CSV; here the same columns
   (accuracy / val_accuracy / loss / val_loss) are supplied inline so the
   epoch-indexing DATA step and the SGPLOT curves below run standalone. */
data work.metrics_DrinkGlas_r1_raw;
  infile datalines dsd truncover;
  input accuracy val_accuracy loss val_loss;
datalines;
0.58,0.54,0.95,0.99
0.66,0.61,0.80,0.86
0.74,0.69,0.62,0.71
0.81,0.74,0.50,0.60
0.86,0.78,0.41,0.53
0.90,0.80,0.34,0.49
;
run;
