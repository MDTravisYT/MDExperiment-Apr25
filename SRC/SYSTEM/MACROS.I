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
WRITEVSRAM	MACRO	LOC,	DEST
		IF	(narg=1)
		MOVE.L	#VSRAMWRITE+((LOC&$3FFF)<<16)+((LOC&$C000)>>14),	VDPCTRL
		ELSE
		MOVE.L	#VSRAMWRITE+((LOC&$3FFF)<<16)+((LOC&$C000)>>14),	DEST
		ENDIF
		ENDM
		
MAPSIZE		MACRO	X,	Y
		move.w	#(X*256)+Y,	MAPSIZE
		ENDM
		
MAPLIMIT	MACRO	X,	Y
		move.l	#((Y*$10000)+2)+(X-1),	d5
		ENDM