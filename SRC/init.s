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
	move.w	#$8B00+%00000000,(VDPCTRL)      ;	MODE REGISTER 3
	move.w	#$8C00+%00000000,(VDPCTRL)      ;	MODE REGISTER 4
	move.w	#$8D00+%00111111,(VDPCTRL)      ;	H-SCROLL DATA LOCATION
	move.w	#$8E00+%00000000,(VDPCTRL)      ;	
	move.w	#$8F00+%00000010,(VDPCTRL)      ;	AUTO-INCREMENT VALUE
	move.w	#$9000+%00000001,(VDPCTRL)      ;	PLANE SIZE
	move.w	#$9100+%00000000,(VDPCTRL)      ;	WINDOW PLANE HORIZONTAL
	move.w	#$9200+%00000000,(VDPCTRL)      ;	WINDOW PLANE VERTICAL
	
	move.l	#CRAMWRITE,(VDPCTRL)
	move.w	#$E0,VDPDATA
	
;	init sound
	z80reset_off
	z80bus_on
	z80reset_on
	lea		pcm_top,a0
	lea		Z80RAM,	a1
	move.w	#(pcm_end-pcm_top)-1,	d0
.loadSound
	move.b	(a0)+,	(a1)+
	dbf		d0,		.loadSound
	z80reset_off
	move.w	#$20,	d0
.stall
	dbf		d0,		.stall
	z80reset_on
	z80bus_off
	jsr		INITJOYPADS	;	init controller
	move	#$2300,sr
	
	move.b	#$81,	sound_ram+buf1

	WRITEVSRAM		;	scroll
	move.w	#8,	VDPDATA		;	scroll screen
	
	move.b	#0,	d0
	bsr.w	LoadArtList

	move.l	#CRAMWRITE,(VDPCTRL)
	lea		pal,	a0
	move.l	#(pal_end-pal)/4-1,	d0
.loadPal
	move.l	(a0)+,VDPDATA
	dbf		d0,	.loadPal
	
;	draw temp sprite
	WRITEVRAM	$F800
	move.w	#$80+$64,	VDPDATA	;	Y POS
	move.w	#%010100000000,	VDPDATA	;	SIZE (2x2)
	move.w	#$4000/$20,	VDPDATA	;	VRAM
	move.w	#$80+$70,	VDPDATA	;	X POS