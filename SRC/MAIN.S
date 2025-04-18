	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
ascii:
	incbin		"src/ascii.art"
	ascii_end:
hex:
	incbin		"src/hex.art"
	hex_end:
	
init:
	move.w	#$8000+%00000100,(VDPCTRL)		;	MODE REGISTER 1
	move.w	#$8100+%01110100,(VDPCTRL)      ;	MODE REGISTER 2
	move.w	#$8200+(PLANE_A>>10),(VDPCTRL)  ;	PLANE A LOCATION
	move.w	#$8300+(PLANE_W>>10),(VDPCTRL)  ;	PLANE W LOCATION
	move.w	#$8400+(PLANE_B>>13),(VDPCTRL)  ;	PLANE B LOCATION
	move.w	#$8500+%01111100,(VDPCTRL)      ;	SPRITE TABLE LOCATION
	move.w	#$8600+%00000000,(VDPCTRL)      ;	
	move.w	#$8700+%00000000,(VDPCTRL)      ;	BACKGROUND COLOR
	move.w	#$8800+%00000000,(VDPCTRL)      ;	MASTER SYSTEM H-SCROLL
	move.w	#$8900+%00000000,(VDPCTRL)      ;	MASTER SYSTEM V-SCROLL
	move.w	#$8A00+%00000000,(VDPCTRL)      ;	H-INT COUNTER
	move.w	#$8B00+%00000111,(VDPCTRL)      ;	MODE REGISTER 3
	move.w	#$8C00+%10000001,(VDPCTRL)      ;	MODE REGISTER 4
	move.w	#$8D00+%00111111,(VDPCTRL)      ;	H-SCROLL DATA LOCATION
	move.w	#$8E00+%00000000,(VDPCTRL)      ;	
	move.w	#$8F00+%00000010,(VDPCTRL)      ;	AUTO-INCREMENT VALUE
	move.w	#$9000+%00000001,(VDPCTRL)      ;	PLANE SIZE
	move.w	#$9100+%00000000,(VDPCTRL)      ;	WINDOW PLANE HORIZONTAL
	move.w	#$9200+%00000000,(VDPCTRL)      ;	WINDOW PLANE VERTICAL
	
	move.l	#CRAMWRITE,(VDPCTRL)
	move.w	#$E0,VDPDATA
	
	lea		ascii,	a0
	lea		VDPDATA,a1
	move.l	#(ascii_end-ascii)/4-1,	d0
	move.l	#VRAMWRITE+$4000000,(VDPCTRL)
.loadASCII1
	move.l	(a0)+,(a1)
	dbf		d0,	.loadASCII1
	lea		hex,	a0
	lea		VDPDATA,a1
	move.l	#(hex_end-hex)/4-1,	d0
	move.l	#VRAMWRITE+1,(VDPCTRL)
.loadhex1
	move.l	(a0)+,(a1)
	dbf		d0,	.loadhex1
	
	InitTXT	ASCIITXT1,ASCIITXT1_END,1,1
	InitTXT	ASCIITXT2,ASCIITXT2_END,1,2
	InitTXT	ASCIITXT3,ASCIITXT3_END,1,3
	
	jsr		_sfxinit	;	init GEMS
	jsr		INITJOYPADS	;	init controller
	move	#$2300,sr
	
	move.l	#CRAMWRITE,(VDPCTRL)
	move.l	#$0EEE,VDPDATA
	move.w	#$0444,VDPDATA
	
	move.l	#$2E,-(sp)
	jsr	_gemsstartsong		; start song
	adda.w	#4,sp
	
.loop:
	jsr		VSync
	
	MOVE.L	#$7C000003,	(VDPCTRL)	;	VRAMWRITE FC00
	add.w	#1,	HSCROLL
	
	move.l	#($380/4)-1, d0
.hscroll:
	move.l	HSCROLL,	(VDPDATA)
	dbf		d0,	.hscroll
	
	bra.s	.loop
	
ASCIITXT1:	dc.b	'WHY DO THEY CALL IT OVEN WHEN YOU OF'
	ASCIITXT1_END:	even
ASCIITXT2:	dc.b	'IN THE COLD FOOD OF OUT HOT EAT THE'
	ASCIITXT2_END:	even
ASCIITXT3:	dc.b	'FOOD'
	ASCIITXT3_END:	even

loadASCII2
.loop
	move.b	(a0)+,d1
	move.w	d1,	(a1)
	dbf		d0,	.loop
	rts
	
VSync:
	move.b	#1,	VSWAIT
.loop:
	tst.b	VSWAIT
	bne.s	.loop
	rts
	
	include		"SRC/SYSTEM/JOYPAD.S"
	include		"SRC/SINE.S"