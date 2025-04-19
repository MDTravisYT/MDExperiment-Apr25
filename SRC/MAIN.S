	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
art:
	incbin		"art/art.unc"
	art_end:	even
map:
	incbin		"art/map.map"
pal:
	incbin		"art/pal.pal"
	pal_end:	even
	
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
	
	lea		art,	a0
	lea		VDPDATA,a1
	move.l	#(art_end-art)/4-1,	d0
	move.l	#VRAMWRITE,(VDPCTRL)
.loadArt
	move.l	(a0)+,(a1)
	dbf		d0,	.loadArt
	
	jsr		_sfxinit	;	init GEMS
	jsr		INITJOYPADS	;	init controller
	move	#$2300,sr
	
	move.l	#CRAMWRITE,(VDPCTRL)
	lea		pal,	a0
	move.l	#(pal_end-pal)/4-1,	d0
.loadPal
	move.l	(a0)+,(a1)
	dbf		d0,	.loadPal
	
	move.l	#$2E,-(sp)
	jsr	_gemsstartsong		; start song
	adda.w	#4,sp
	
	PRINTMAP	map,PLANE_A,40,28
	
.loop:
	jsr		VSync
	
	MOVE.L	#$7C000003,	(VDPCTRL)	;	VRAMWRITE FC00
	add.w	#1,	SINOFF
	move.w	SINOFF,	SINOFF2
	
	move.l	#($380/4)-1, d2
.hscroll:
	add.w	#1,	SINOFF2
	move.w	SINOFF2,	d0
	bsr.w	CALCSINE
	lsr.w	#4,	d0
	btst	#0,	SINOFF2+1
	bne.s	.cont
	neg.w	d0
.cont
	move.w	d0,	HSCROLL
	move.l	HSCROLL,	(VDPDATA)
	dbf		d2,	.hscroll
	
	bra.s	.loop
	
VSync:
	move.b	#1,	VSWAIT
.loop:
	tst.b	VSWAIT
	bne.s	.loop
	rts
	
	include		"SRC/SYSTEM/JOYPAD.S"
	include		"SRC/SINE.S"
	include		"SRC/DRAWTILEMAP.S"