	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
	
	include		"src/init.s"
	
;	== MAIN LOOP ====================================

	lea		mapset,	a1
	MAPSIZE	20,	19
	bsr.w	MakeMapInit

;	move.l	#CRAMWRITE,(VDPCTRL)	;	making sure were not looping
;	move.w	#$E0,VDPDATA

.loop:
	moveq	#0,			d0
	WRITEVRAM	$FC00, VDPCTRL		;	scroll
	move.b	SCREENX,	d0
	neg.w	d0
	lsl.w	#5,			d0
	move.w	d0,	VDPDATA		;	scroll screen
	
	jsr		VSync
	btst	#bitL,	JOYPADPRESS
	bne.s	.l
	btst	#bitR,	JOYPADPRESS
	bne.s	.r
	btst	#bitUp,	JOYPADPRESS
	bne.s	.u
	btst	#bitDn,	JOYPADPRESS
	bne.s	.d
	
	bra.s	.loop

.l
	sub.b	#1,	SCREENX
	lea		mapset,	a1
	move.b	#0,		d1	;	left
	moveq	#0,		d7	;	clear row mode
	bsr.w	MakeColumn
	bra.s	.loop
.r
	add.b	#1,	SCREENX
	lea		mapset,	a1
	move.b	#1,		d1	;	right
	moveq	#0,		d7	;	clear row mode
	bsr.w	MakeColumn
	bra.s	.loop
.u
	sub.b	#1,	SCREENY
	lea		mapset,	a1
	move.b	#2,		d1	;	up
	moveq	#1,		d7	;	set row mode
	bsr.w	MakeColumn
	bra.w	.loop
.d
	add.b	#1,	SCREENY
	lea		mapset,	a1
	move.b	#3,		d1	;	down
	moveq	#1,		d7	;	set row mode
	bsr.w	MakeColumn
	bra.w	.loop

	
;	== PRINT MAP (SUB) =--===========================

MakeColumn:
	moveq	#0,			d0
	WRITEVRAM	$FC00, VDPCTRL		;	scroll
	move.b	SCREENX,	d0
	neg.w	d0
	lsl.w	#5,			d0
	move.w	d0,	VDPDATA		;	scroll screen

	MAPLIMIT	1, 8
	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
	moveq	#0,			d0
	move.b	SCREENX,	d0
	tst.b	d7					;	skip if row
	bne.s	.cont
	tst.b	d1
	beq.s	.left
	add.b	#10,		d0		;offset for right
	add.w	#10,		a1		;offset for right
	bra.s	.cont
.left
	sub.b	#16,		d0		;offset for left
.cont
	and.b	#%00001111,	d0	;	wrap shift prevention
	lsl.l	#8,			d0	;	goal: 20000
	lsl.l	#8,			d0	;	goal: 20000
	lsl.l	#3,			d0	;	at:   20000
	add.l	d0,			d3	;	add X offset to writer
	moveq	#0,			d0
	tst.b	d7				;	go to row creation if row mode
	bne.s	MakeRow
	bra.s	MakeMap

MakeRow:
	moveq	#0,			d0
	WRITEVSRAM		;	scroll
	move.b	SCREENY,	d0
	lsl.w	#5,			d0
	move.w	d0,	VDPDATA		;	scroll screen
	
	MAPLIMIT	11, 1
	move.b	SCREENY,	d0
	
	moveq	#0,			d2
	move.b	MAPSIZE,	d2
	mulu.w	#7,			d2
	
	cmpi.b	#2,			d1
	beq.s	.up
	add.w	d2,			a1	;	down
	sub.b	#1,			d0
	bra.s	.cont
.up
;	sub.w	MAPSIZE,	a1	;	up
;	add.b	#1,			d0
	nop
	
.cont
	moveq	#0,			d2
	move.b	MAPSIZE+1,	d2
	and.w	#%00000111,	d2	;	wrap leak prevention
	add.w	#1,			d2
	mulu.w	d2,			d0
	lsl.l	#8,			d0	;	goal: 800000, at 100
	lsl.l	#8,			d0	;	goal: 800000, at 10000
	lsl.l	#7,			d0	;	goal: 800000, at 800000
	add.l	d0,			d3	;	add X offset to writer
	cmpi.l	#$50000000,	d3	;	make sure we don't fall out of bounds
	blo.s	.skipYreset
	and.l	#%11101111111111111111111111111111,d3
.skipYreset
	bra.s	MakeMap

MakeMapInit:
	MAPLIMIT	11, 8
	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
	
MakeMap:
	move.l	d5,		d6		;	backup limiter
	moveq	#0,			d0
	moveq	#0,			d1
	move.b	SCREENX,	d0
	add.w	d0,			a1	;	offset map data horizontally
	
	moveq	#0,			d1
	move.b	SCREENY,	d0
	move.b	MAPSIZE+1,	d1
	add.w	#1,			d1
	mulu.w	d1,			d0
	add.w	d0,			a1	;	offset map data vertically
	moveq	#0,			d0
	
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
	tst.b	d7					;	test for row mode
	beq.s	.skipYreset
	btst	#$17,		d3		;	make sure we don't fall out of bounds
	beq.s	.skipYreset
	sub.l	#$800000,	d3
.skipYreset
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
	add.l	#$2000000,	d3		;	move drawer to next position
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
;	jsr		VSync	;	TEMP
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
	move.w		d0,	VDPDATA
;	jsr		VSync	;	TEMP
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
	incbin		"src/ViridianCity.blk"
	even