/**********************************************************************************************************************/
/* Program name:    04_plot_training_metrics.sas                                                                      */
/* Programmer:      Brandon Hopkins                                                                                   */
/* Purpose:         Import model training metrics from CSV, append epoch index, and generate PDF plots of accuracy    */
/*                  and loss curves for each task and round.                                                          */
/* Input:           /tmp/model_metrics_[task].csv                                                                     */
/* Output:          /tmp/plot_[task]_r[round].pdf – Accuracy and Loss curves by epoch                                 */
/**********************************************************************************************************************/

%macro import_metrics(task, round);
  proc import datafile="/tmp/model_metrics_&task..csv"
    out=work.metrics_&task._r&round.
    dbms=csv
    replace;
    guessingrows=max;
  run;

  data metrics_&task._r&round.;
    set metrics_&task._r&round.;
    epoch = _N_;
  run;
%mend import_metrics;


%import_metrics(DrinkGlas, 1)
%import_metrics(Entrainment, 1)
%import_metrics(LiftHold, 1)
%import_metrics(TouchNose, 1)

%import_metrics(Entrainment_r2_deep, 2)
%import_metrics(TouchNose_r2_deep, 2)


%import_metrics(Entrainment_r4_wghtd, 4)





%macro plotter(task, round);
    ods pdf file="/tmp/plot_&task._r&round..pdf" style=journal;
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
    ods pdf close;
%mend plotter;


%plotter(DrinkGlas, 1)
%plotter(Entrainment, 1)
%plotter(LiftHold, 1)
%plotter(TouchNose, 1)


%plotter(Entrainment_r2_deep, 2)
%plotter(TouchNose_r2_deep, 2)


options mprint;
%plotter(Entrainment_r4_wghtd, 4)

proc sgplot data=metrics_Entrainment_r4_wghtd_r4;
  title "Entrainment Model — Final Round (Confidence-Thresholded, Weighted)";
  series x=epoch y=accuracy / lineattrs=(color=blue pattern=solid) legendlabel="Train Accuracy";
  series x=epoch y=val_accuracy / lineattrs=(color=blue pattern=shortdash) legendlabel="Val Accuracy";
  series x=epoch y=loss / lineattrs=(color=red pattern=solid) legendlabel="Train Loss";
  series x=epoch y=val_loss / lineattrs=(color=red pattern=shortdash) legendlabel="Val Loss";
  xaxis label="Epoch";
  yaxis label="Metric Value";
  keylegend / position=bottom;
run;