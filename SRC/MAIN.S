	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"sound/src/tb.lib"
	include		"sound/src/eq.lib"
	include		"sound/src/mcr.lib"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	
	include		"src/init.s"
	
;	== MAIN LOOP ====================================

	move.b	#0,	MAP
	bsr.w	MakeMapInit

;	move.l	#CRAMWRITE,(VDPCTRL)	;	making sure were not looping
;	move.w	#$E0,VDPDATA

.loop:
	jsr		VSync
;	lea		mapset,	a1
	btst	#bitL,	JOYPADPRESS
	bne.w	.l
	btst	#bitR,	JOYPADPRESS
	bne.w	.r
	btst	#bitUp,	JOYPADPRESS
	bne.w	.u
	btst	#bitDn,	JOYPADPRESS
	bne.w	.d
	btst	#bitStart,	JOYPADPRESS
	bne.w	.nextmap
	
	bra.s	.loop
	
.nextmap
	add.b	#1,	MAP
	move.w	#0,	SCREENX	;	does both X and Y size, since theyre bytes
	WRITEVRAM	$FC00,	VDPCTRL		;	scroll
	move.w		#0,		VDPDATA
	WRITEVSRAM
	move.w		#0,		VDPDATA
	bsr.w	MakeMapInit
	bra.s	.loop

.l
	sub.b	#1,	SCREENX
	move.b	SCREENX,	d0
	move.b	MAPSIZE,	d1
	cmp.b	d0,			d1
	blo.s	.resetL
	move.b	#0,		d1	;	left
	moveq	#0,		d7	;	clear row mode
	bsr.w	MakeColumn
	bra.w	.loop
.resetL
	move.b	#0,	SCREENX
	bra.w	.loop
.r
	add.b	#1,	SCREENX
	move.b	SCREENX,	d0
	move.b	MAPSIZE,	d1
	sub.b	#8,		d1
	cmp.b	d0,			d1
	blo.s	.resetR
	move.b	#1,		d1	;	right
	moveq	#0,		d7	;	clear row mode
	bsr.w	MakeColumn
	bra.w	.loop
.resetR
	move.b	d1,		SCREENX
	bra.w	.loop
.u
	sub.b	#1,	SCREENY
	move.b	SCREENY,	d0
	move.b	MAPSIZE+1,	d1
	cmp.b	d0,			d1
	blo.s	.resetU
	move.b	#2,		d1	;	up
	moveq	#1,		d7	;	set row mode
	bsr.w	MakeColumn
	bra.w	.loop
.resetU
	move.b	#0,	SCREENY
	bra.w	.loop
.d
	add.b	#1,	SCREENY
	move.b	SCREENY,	d0
	move.b	MAPSIZE+1,	d1
	sub.b	#8,		d1
	cmp.b	d0,			d1
	blo.s	.resetD
	move.b	#3,		d1	;	down
	moveq	#1,		d7	;	set row mode
	bsr.w	MakeColumn
	bra.w	.loop
.resetD
	move.b	d1,		SCREENY
	bra.w	.loop
	
;	== INIT MAP (SUB) =--===========================
InitMap:
	moveq	#0,		d0
	move.b	MAP,	d0
	lea		maptbl,	a0
	lsl.w	#3,		d0
	add.w	d0,		a0
	move.l	(a0)+,	a1	;	map data
	move.w	(a0)+,	MAPSIZE	;	map dimensions
	
	rts

;	== PRINT MAP (SUB) =--===========================

MakeColumn:
	bsr.w	InitMap
	moveq	#0,			d0
	WRITEVRAM	$FC00, VDPCTRL		;	scroll
	move.b	SCREENX,	d0
	neg.w	d0
	lsl.w	#5,			d0
	move.w	d0,	VDPDATA		;	scroll screen

	MAPLIMIT	1, 8
	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
	
	move.b	SCREENY,	d0
	
	moveq	#0,			d2
	move.b	MAPSIZE,	d2
	mulu.w	#7,			d2
	
	cmpi.b	#3,			d1
	bne.s	.cont2
	add.w	d2,			a1	;	down
	sub.b	#1,			d0
	
.cont2
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
	add.b	#8,			d0
	move.w	d0,	VDPDATA		;	scroll screen
	MAPLIMIT	11, 1
	bra.s	MakeMap

MakeMapInit:
	bsr.w	InitMap
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
	beq.s	.skipXreset
	btst	#$17,		d3		;	make sure we don't fall out of bounds
	beq.s	.skipXreset
	sub.l	#$800000,	d3
.skipXreset
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
	btst	#$1C,		d3		;	make sure we don't fall out of bounds
	beq.s	.skipYreset
	sub.l	#$10000000,	d3
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
.noDraw
	dbf			d1,	.loop1		;	horizontal loop
	add.l		#$800000,d3		;	move drawer down one
	dbf			d2,	.loop2		;	vertical loop
	sub.b		#1,	d4			;	subtract counter from MakeMap
	rts

;	== INCLUDES =====================================
maptbl:
	MAPDEF	MAP001,	20,	19
	MAPDEF	MAP002,	10,	36
	MAPDEF	MAP003,	10,	9
	MAPDEF	MAP004,	20,	19
	MAPDEF	MAP005,	30,	9
	
	include		"SRC/SYSTEM/JOYPAD.S"
	include		"SRC/SYSTEM/VSYNC.S"
	include		"SRC/SUB/LOADART.S"
	
art:
	incbin		"art/overworld.bin"
	art_end:	even
redart:
	incbin		"art/red.bin"
	redart_end:	even
pal:
	dc.w		$000
	dc.w		$666
	dc.w		$AAA
	dc.w		$EEE
	pal_end:	even
blkset:
	incbin		"blocks/overworld.bst"
	even
MAP001:
	incbin		"maps/ViridianCity.blk"
	even
MAP002:
	incbin		"maps/Route1.blk"
	even
MAP003:
	incbin		"maps/PalletTown.blk"
	even
MAP004:
	incbin		"maps/SaffronCity.blk"
	even
MAP005:
	incbin		"maps/Route13.blk"
	even
	
	align		$1000
	include		"sound/sound.s"