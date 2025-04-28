INITSOUND:
	z80reset_off
	z80bus_on
	z80reset_on
	lea		pcm_top,a0
	lea		Z80RAM,	a1
	move.w	#(pcm_end-pcm_top)-1,	d0
.load
	move.b	(a0)+,	(a1)+
	dbf		d0,		.load
	z80reset_off
	move.w	#$20,	d0
.stall
	dbf		d0,		.stall
	z80reset_on
	z80bus_off
	rts
	

	include		"sound/data/tb.asm"
	include		"sound/data/sng81.s"
	include		"sound/data/sng82.s"
	include		"sound/data/sng83.s"
	include		"sound/data/sng84.s"
	include		"sound/data/sng85.s"
	include		"sound/data/sng86.s"
	include		"sound/data/sng87.s"
	include		"sound/data/sng88.s"
	include		"sound/data/sng89.s"
	include		"sound/data/sng8a.s"
	include		"sound/data/sng8b.s"
	include		"sound/data/sng8c.s"
	include		"sound/data/sng8d.s"
	include		"sound/data/sng8e.s"
	include		"sound/data/sng8f.s"
	include		"sound/data/setb.asm"
	
	include		"sound/data/se1.s"
	include		"sound/data/se2.s"
	include		"sound/data/se3.s"
	include		"sound/data/bse.s"
;	
	even
	include		"sound/src/cnt.asm"
	include		"sound/src/cmd.asm"
	include		"sound/src/psg.asm"
	include		"sound/src/pcm.asm"