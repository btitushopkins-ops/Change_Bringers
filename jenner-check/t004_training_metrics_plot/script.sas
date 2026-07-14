/* Epoch-indexing + training-curve plotting from "05 plot cnn models.sas"
   (Brandon Hopkins).
   The import_metrics macro appends epoch = _N_ to the imported metrics table;
   the plotter macro draws the accuracy/loss curves with PROC SGPLOT. Here the
   PROC IMPORT of /tmp/model_metrics_<task>.csv is replaced by the mock table
   in autoexec (same columns), so the epoch logic and the exact SGPLOT series
   below run standalone. */

%macro import_metrics(task, round);
  data metrics_&task._r&round.;
    set work.metrics_&task._r&round._raw;
    epoch = _N_;
  run;
%mend import_metrics;

%import_metrics(DrinkGlas, 1)

%macro plotter(task, round);
    proc sgplot data=metrics_&task._r&round.;
        title "&task - Accuracy and Loss (Round &round)";
        series x=epoch y=accuracy     / lineattrs=(color=blue pattern=solid)     legendlabel="Train Accuracy";
        series x=epoch y=val_accuracy / lineattrs=(color=blue pattern=shortdash) legendlabel="Val Accuracy";
        series x=epoch y=loss         / lineattrs=(color=red pattern=solid)      legendlabel="Train Loss";
        series x=epoch y=val_loss     / lineattrs=(color=red pattern=shortdash)  legendlabel="Val Loss";
        xaxis label="Epoch";
        yaxis label="Metric Value";
        keylegend / position=bottom;
    run;
%mend plotter;

options mprint;
%plotter(DrinkGlas, 1)

proc print data=metrics_DrinkGlas_r1; run;
