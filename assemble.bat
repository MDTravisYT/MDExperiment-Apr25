@echo off
if not exist OUT mkdir OUT
"TOOL/vasmm68k_psi-x.exe" -altlocal -m68000 -maxerrors=0 -Fbin -start=0 -o "OUT/MD0425.BIN" -L "OUT/MD0425.LST" -Lall "SRC/MAIN.S" 2> _errors.log
type _errors.log
del _errors.log
pause