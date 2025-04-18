InitTXT	macro	src,end,x,y
	lea		src,	a0
	lea		VDPDATA,a1
	move.l	#(end-src)-1,	d0
	move.l	#$40000002+(x*$20000)+(y*$800000),(VDPCTRL)
	moveq	#0,	d1
	jsr		loadASCII2
	endm
	
PRINTMAP		MACRO	source,loc,width,height
		lea		(source).l,a1
		move.l	#$40000000+((loc&$3FFF)<<16)+((loc&$C000)>>14),d0
		moveq	#width-1,d1
		moveq	#height-1,d2
		jsr		DrawTileMap
		endm
		
WRITEVRAM	MACRO	LOC
		MOVE.L	#VRAMWRITE+((LOC&$3FFF)<<16)+((LOC&$C000)>>14),	(VDPCTRL)
		ENDM