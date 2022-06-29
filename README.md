# Acoustics DSP toolbox for Matlab
 Repo with useful functions and routines for acoustic digital signal processing purposes.

## Background 

 Since the first semester of 2021, I've been helping as a volunteer teaching assistant in the Acoustical Engineering program at UFSM (Brazil). Due to this work, I've developed several functions and routines to ease my tasks and also help other students grasp some digital signal processing concepts.
 
Recently, I've organized everything and decided to make all functions public, so anyone can find and use them. Feel free to contact me if you find any bugs or conceptual errors. I'll be glad to fix those and learn a bit more!

## Routines description

 1. `easyWindow.m`: this routine is useful when you need to apply a time window to an impulse response (to remove reflections, for example).
 2. `expSweep.m`: plain and simple exponential sweep generator. However, there is also an amplitude modulation option that allows for the construction of sweeps with different frequency response slopes.
 3. `fredPlot`: this one I use a lot. Basically, it configures a figure the way I like it.
 4. `ssFFT`: function to quickly calculate a single-sided FFT with four amplitude modes (peak, RMS, power, and complex).
 5. `centerFreqsCalculator`: calculates fractional octave bands center (and edge) frequencies according to ANSI S1.11-2004.
 6. `octaveFilterBankGenerator`: generates a bank of fractional octave bands IIR filters according to ANSI S1.11-2004.
 7. `octaveSPL`: uses a filter bank from octaveFilterBankGenerator to calculate sound pressure level in fractional octave bands.
 8. `splCalculator`: calculates equivalente continuous sound pressure levels (broadband) with A, C, and Z frequency weightings (and instantaneous SPL with Fast and Slow time-weightings).
 9. `timeWeightingFilterGenerator`: generates IIR filters for Fast and Slow time-weightings used in Sound Level Meters.
 10. `itaSPL`: calculates SPL from an ITA audio object.
