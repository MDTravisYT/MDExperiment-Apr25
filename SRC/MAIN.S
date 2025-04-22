	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
	
	include		"src/init.s"
	
;	== MAIN LOOP ====================================

	lea		mapset,	a1
	move.w	#$0A09,	MAPSIZE ; (X 10 Y 9)
	bsr.w	MakeMap

.loop:
	jsr		VSync
	
	bra.s	.loop
	
	
;	== PRINT MAP (SUB) =--===========================

MakeMap:
	move.b	MAPSIZE+1,	d4	;	YMODE: Y length
	swap	d4				;	storing both in same register
	move.b	MAPSIZE,	d4	;	XMODE: X length
	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
.loopX
	tst.b	d4				;	check if X length is used up
	beq.s	.exit
	bsr.s	MakeChunk
	sub.l	#$1F80000,d3		;	move drawer to next position
	bra.s	.loopX
	
.exit
	rts

;	== PRINT CHUNK (SUB) ============================

MakeChunk:
	jsr		VSync	;	TEMP
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
	move.w		d0,	VDPDATA
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
	incbin		"src/PalletTown.blk"
	even