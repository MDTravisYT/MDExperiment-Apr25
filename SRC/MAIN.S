	include		"src/system/macros.i"
	include		"src/system/equates.i"
	include		"src/system/vectors.s"
	include		"src/system/error.s"
	include		"src/system/interrupt.s"
	include		"GEMS/sound.s"
	
	include		"src/init.s"
	
.loop:
	jsr		VSync
	
	bra.s	.loop
	
VSync:
	move.b	#1,	VSWAIT
.loop:
	tst.b	VSWAIT
	bne.s	.loop
	rts
	
	include		"SRC/SYSTEM/JOYPAD.S"
	
art:
	incbin		"art/art.unc"
	art_end:	even
pal:
	incbin		"art/pal.pal"
	pal_end:	even
blkset:
	incbin		"src/overworld.bst"
	even