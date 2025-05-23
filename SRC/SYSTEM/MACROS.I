InitTXT	macro	src,end,x,y
	lea		src,	a0
	lea		VDPDATA,a1
	move.l	#(end-src)-1,	d0
	move.l	#$40000002+(x*$20000)+(y*$800000),(VDPCTRL)
	moveq	#0,	d1
	jsr		loadASCII2
	endm
		
WRITEVRAM	MACRO	LOC,	DEST
		IF	(narg=1)
		MOVE.L	#VRAMWRITE+((LOC&$3FFF)<<16)+((LOC&$C000)>>14),	VDPCTRL
		ELSE
		MOVE.L	#VRAMWRITE+((LOC&$3FFF)<<16)+((LOC&$C000)>>14),	DEST
		ENDIF
		ENDM
		
WRITEVSRAM	MACRO
		MOVE.L	#VSRAMWRITE,	VDPCTRL
		ENDM
		
MAPDEF	MACRO	LOC,	X,	Y
		dc.l	LOC
		dc.w	(X*256)+Y
		dc.w	0	;	dummy to make math easier for 2:30 AM mind
		ENDM
		
	;	vvv Moves into d5 vvv
MAPLIMIT	MACRO	X,	Y
		move.l	#((Y*$10000)+2)+(X-1),	d5
		ENDM
		
ARTLIST		MACRO	LOC,	DEST
		dc.w	((\LOC\_end-LOC)/4)-1
		dc.l	VRAMWRITE+((DEST&$3FFF)<<16)+((DEST&$C000)>>14)
		dc.l	LOC
		ENDM
		
ARTLIST_END	MACRO
		dc.l	-1
		even
		ENDM