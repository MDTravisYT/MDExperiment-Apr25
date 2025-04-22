	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
	
	include		"src/init.s"
	
;	== MAIN LOOP ====================================

	move.b	#0,	CHUNKID
	move.b	CHUNKID, d0
	bsr.w	MakeChunk

.loop:
	jsr		VSync
	btst	#bitR,	JOYPADPRESS
	bne.s	.shiftChunk
	btst	#bitL,	JOYPADPRESS
	bne.s	.shiftChunkBack
	
	bra.s	.loop
	
.shiftChunk
	add.b	#1,	CHUNKID
	move.b	CHUNKID, d0
	bsr.w	MakeChunk
	bra.s	.loop
	
.shiftChunkBack
	sub.b	#1,	CHUNKID
	move.b	CHUNKID, d0
	bsr.w	MakeChunk
	bra.s	.loop
	
	
;	== PRINT CHUNK (SUB) ============================

MakeChunk:
	lea			blkset,	a0		;	storing reference point in a0
	lsl.w		#4,		d0		;	multiply d0 by 16 (bytes in a chunk)
	add.w		d0,		a0		;	shift over chunk by amount
	
	moveq		#0,		d0		;	storing tile ID in d0, clearing to remove excess garbage on high word
	WRITEVRAM	PLANE_A,d3		;	reference raw VRAM pointer
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