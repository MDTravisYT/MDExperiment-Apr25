ascii:
	incbin	"SRC\SYSTEM\ASCII.ART"
	ascii_end:

errBus:
	InitTXT	ASCIITXT1,ASCIITXT1_END,2,2
	bra.w	Err_cont
errAddress:
	InitTXT	ASCIITXT2,ASCIITXT2_END,2,2
	bra.w	Err_cont
errIllegal:
	InitTXT	ASCIITXT3,ASCIITXT3_END,2,2
	bra.w	Err_cont
errZeroDiv:
	InitTXT	ASCIITXT4,ASCIITXT4_END,2,2
	bra.w	Err_cont
errChkInst:
	InitTXT	ASCIITXT5,ASCIITXT5_END,2,2
	bra.w	Err_cont
errPriViol:
	InitTXT	ASCIITXT6,ASCIITXT6_END,2,2
	bra.w	Err_cont
errTrace:
	InitTXT	ASCIITXT7,ASCIITXT7_END,2,2
	bra.w	Err_cont
errLine1010:
	InitTXT	ASCIITXT8,ASCIITXT8_END,2,2
	bra.w	Err_cont
errLine1111:
	InitTXT	ASCIITXT9,ASCIITXT9_END,2,2
	bra.w	Err_cont
errTrapV:
	InitTXT	ASCIITXT10,ASCIITXT10_END,2,2
	bra.w	Err_cont
trap:
	InitTXT	ASCIITXT10,ASCIITXT10_END,2,2
Err_cont:
	bsr.w	LoadASCIIArt
Err_loop:	
	move.l	#CRAMWRITE,(VDPCTRL)
	move.w	#$E,VDPDATA
	bra.s	Err_loop
	
LoadASCIIArt:
	lea		ascii,	a0
	lea		VDPDATA,a1
	move.l	#(ascii_end-ascii)/4-1,	d0
	move.l	#VRAMWRITE+$4000000,(VDPCTRL)
.loadASCII1
	move.l	(a0)+,(a1)
	dbf		d0,	.loadASCII1
	rts
	
loadASCII2
.loop
	move.b	(a0)+,d1
	move.w	d1,	(a1)
	dbf		d0,	.loop
	rts
	
ASCIITXT1:	dc.b	'BUS ERROR'
	ASCIITXT1_END:	even
ASCIITXT2:	dc.b	'ADDRESS ERROR'
	ASCIITXT2_END:	even
ASCIITXT3:	dc.b	'ILLEGAL INSTRUCTION'
	ASCIITXT3_END:	even
ASCIITXT4:	dc.b	'ZERO DIVISON'
	ASCIITXT4_END:	even
ASCIITXT5:	dc.b	'CHK INSTRUCTION'
	ASCIITXT5_END:	even
ASCIITXT6:	dc.b	'PRIVILEGE VIOLATION'
	ASCIITXT6_END:	even
ASCIITXT7:	dc.b	'TRACE'
	ASCIITXT7_END:	even
ASCIITXT8:	dc.b	'LINE 1010'
	ASCIITXT8_END:	even
ASCIITXT9:	dc.b	'LINE 1111'
	ASCIITXT9_END:	even
ASCIITXT10:	dc.b	'TRAP!'
	ASCIITXT10_END:	even