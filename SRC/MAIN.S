	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
	
	include		"src/init.s"
	
;	== MAIN LOOP ====================================

	lea		mapset,	a1
	MAPSIZE	20,	18
	MAPLIMIT 10, 7
	bsr.w	MakeMap

;	move.l	#CRAMWRITE,(VDPCTRL)	;	making sure were not looping
;	move.w	#$E0,VDPDATA

.loop:
	jsr		VSync
	btst	#bitR,	JOYPADPRESS
	bne.s	.progR
	btst	#bitL,	JOYPADPRESS
	bne.s	.progL
	btst	#bitDn,	JOYPADPRESS
	bne.s	.progD
	btst	#bitUp,	JOYPADPRESS
	bne.s	.progU
	
	bra.s	.loop
	
.progR
	add.b	#1,	XPOS
	lea		mapset,	a1
	bra.s	.cont
.progL
	sub.b	#1,	XPOS
	lea		mapset,	a1
	bra.s	.cont
.progD
	add.b	#1,	YPOS
	lea		mapset,	a1
	bra.s	.cont
.progU
	sub.b	#1,	YPOS
	lea		mapset,	a1
;	bra.s	.cont
	
.cont
	WRITEVRAM	$FC00
	move.b	XPOS,	d0
	lsl.w	#5,		d0
	neg.w	d0
	move.w	d0,		VDPDATA
	WRITEVSRAM	0
	move.b	YPOS,	d0
	lsl.w	#5,		d0
	move.w	d0,		VDPDATA
	MAPLIMIT 11, 8
	bsr.w	MakeMap
	bra.w	.loop
	
	
;	== PRINT MAP (SUB) =--===========================

;LIMITX	=	3-1		;	12
;LIMITY	=	2-1		;	8

MakeMap:
	move.l		d5,		d6		;	backup limiter
	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
	moveq		#0,		d0		;	wipe d0
	move.b		XPOS,	d0		;	grab X position
	move.l		a1,		d1		;	can't add data register into address so gotta compromise
	add.w		d0,		d1		;	move over map offset
	and.b		#$0F,	d0		;	destroy high nybble (no wrapping!!)
	swap		d0				;	convert to VRAM offset	(00000001 > 00010000)
	lsl.l		#3,		d0		;	convert to VRAM offset	(00010000 > 00080000)
	add.l		d0,		d3		;	add to VRAM offset

	moveq		#0,		d0		;	wipe d0
	move.b		YPOS,	d0		;	grab Y position
	tst.b		d0				;	are we at the top of the map
	beq.s		.skipYoff		;	skip if so
	moveq		#0,		d2		;	wipe d2
	move.b		MAPSIZE,d2		;	grab map Xsize
	sub.b		#1,		d0		;	for dbf (always runs one more than told)
.loopYoff
	add.w		d2,		d1		;	get offset for data
	add.l	#$2000000,d3		;	move drawer to next position
	dbf			d0,		.loopYoff
.skipYoff
	move.l		d1,		a1		;	move back into a1 (map data)
	moveq		#0,		d0		;	wipe d0
	move.b	MAPSIZE+1,	d4	;	YMODE: Y length
	swap	d4				;	storing both in same register
;	move.l	#(LIMITY*$10000)+LIMITX,	d5	;	Limiter so screen doesnt draw over itself when map's too big (8 down, 16 across)
	
.loopX2
	move.b	MAPSIZE,	d4	;	XMODE: X length
	
.loopX
	tst.b		d5
	beq.s	.cont
	sub.b		#1,	d5	;	X Limiter
.cont
	tst.b	d4				;	check if X length is used up
	beq.s	.tstY
	bsr.s	MakeChunk
	sub.l	#$1F80000,d3		;	move drawer to next position
	bra.s	.loopX
	
.tstY
	move.b	d6,		d5	;	X Limiter
	swap	d5			;	YLIMIT
	sub.b	#1,		d5
	tst.b	d5
	beq.s	.exit
	swap	d5			;	XLIMIT
	swap	d4				;	YMODE
	tst.b	d4				;	YMODE
	bne.s	.loopY
	
.exit
	rts
	
.loopY
	add.l	#$2000000,d3		;	move drawer to next position
	cmpi.l	#$50000000,d3		;	make sure we don't fall out of bounds
	blo.s	.skipYreset
	sub.l	#$10000000,d3
.skipYreset
	sub.b	#1,	d4	;	YMODE
	swap	d4		;	XMODE
	move.b	MAPSIZE,	d4	;	XMODE: X length
.rollbackX
	tst.b	d4				;	check if X length is used up
	beq.s	.loopX2
	sub.l	#$80000,	d3
	sub.b	#1,	d4	;	XMODE
	bra.s	.rollbackX

;	== PRINT CHUNK (SUB) ============================

MakeChunk:
	lea			blkset,	a0		;	storing reference point in a0
	move.b		(a1)+,	d0		;	move map chunk data to d0
	lsl.w		#4,		d0		;	multiply d0 by 16 (bytes in a chunk)
	add.w		d0,		a0		;	shift over chunk by amount
	
	moveq		#0,		d0		;	storing tile ID in d0, clearing to remove excess garbage on high word
;	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
	move.l		#4-1,	d2		;	vertical timer   (v)
.loop2
	move.l		d3,		VDPCTRL	;	update draw position
	move.l		#4-1,	d1		;	horizontal timer (>)
.loop1
	move.b		(a0)+,	d0		;	gotta convert that byte into a word so VDP likes it!
	tst.b		d5				;	limiter
	beq.s		.noDraw			;	don't draw if limit reached
;	jsr		VSync	;	TEMP
	move.w		d0,	VDPDATA
.noDraw
	dbf			d1,	.loop1		;	horizontal loop
	add.l		#$800000,d3		;	move drawer down one
	dbf			d2,	.loop2		;	vertical loop
	sub.b		#1,	d4			;	subtract counter from MakeMap
	rts

;	== INCLUDES =====================================
	
	include		"SRC/SYSTEM/JOYPAD.S"
	include		"SRC/SYSTEM/VSYNC.S"
	
art:
	incbin		"art/art.unc"
	art_end:	even
pal:
	incbin		"art/pal.pal"
	pal_end:	even
blkset:
	incbin		"src/overworld.bst"
	even
mapset:
	incbin		"src/SaffronCity.blk"
	even