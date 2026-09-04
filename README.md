# AHDS — Practical Circuit Analysis with MATLAB

This repository presents practical examples of electronic circuit analysis using MATLAB as an engineering tool.

Each example combines circuit design, theoretical calculations, MATLAB modeling, waveform generation, and comparison with electrical simulation results.

Topics include timing circuits, analog electronics, filters, transistor and MOSFET circuits, operational amplifiers, sensors, power electronics, and other practical hardware design applications.

Example #01: NE555 Astable LED Flasher — theoretical calculations, timing analysis, MATLAB modeling, waveform visualization, and electrical simulation.
Example #2 — NE555 PWM LED Dimmer: Circuit Analysis with MATLAB

This example demonstrates the analysis and simulation of a PWM LED dimmer based on the NE555 timer.

The NE555 generates a variable-duty-cycle PWM signal used to control the current and average power delivered to an LED load. The circuit is analyzed mathematically and simulated using MATLAB, allowing the relationship between the PWM duty cycle, LED current, switching device losses, and load size to be visualized.

The MATLAB script included in this example:

calculates the approximate PWM frequency and timing parameters;
simulates the NE555 timing capacitor charge/discharge cycle;
generates PWM waveforms for different duty cycles;
calculates instantaneous and average LED current;
compares conduction losses between a BJT and an N-channel MOSFET;
evaluates the effect of increasing the number of LEDs;
automatically generates and saves seven simulation graphs as PNG files.
