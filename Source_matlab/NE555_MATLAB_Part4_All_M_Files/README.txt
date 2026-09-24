NE555 Current-Sense MATLAB Study - Part 4
============================================

MATLAB source files extracted from the annotated study report.

Files:
1. NE555_Current_Sense_All_Test_Points.m
   Version 1 - original 330 kOhm baseline with slow current ramps.

2. NE555_Current_Sense_All_Test_Points_V2.m
   Version 2.0 - fast 0 A -> 10 A -> 0 A current-step experiment.

3. NE555_Current_Sense_All_Test_Points_V2_1.m
   Version 2.1 - MATLAB Online robust plotting revision.

4. NE555_Current_Sense_All_Test_Points_V2_2.m
   Version 2.2 - export-only plotting revision.

5. NE555_Current_Sense_All_Test_Points_V2_3.m
   Version 2.3 - final 330 kOhm baseline with PNG and CSV export.

6. NE555_Current_Sense_R36_Gain_Sweep_V3_0.m
   Version 3.0 - R36 / LM358 gain sweep.

7. V3_0_Plot_Test_From_CSV.m
   Helper program for plotting the Version 3.0 CSV independently.

Important:
These files reproduce the behavioral MATLAB study. The Q6 threshold and
frequency-sensitivity coefficient are modeling assumptions, not yet
bench-validated physical constants.
