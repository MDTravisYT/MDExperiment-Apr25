LoadArtList:
	lea		ArtLists,	a0
	and.l	#$FF,		d0
	lsl.w	#1,			d0	;	multiply by 2
	add.l	d0,			a0
	add.w	(a0),		a0
	sub.l	d0,			a0
.loop
	move.w	(a0)+,		d0
	and.w	#$FFFF,		d0
	move.l	(a0)+,		VDPCTRL
	move.l	(a0)+,		a1
	bsr.s	LoadArt
	cmp.l	#-1,		(a0)
	bne.s	.loop
	rts

LoadArt:
	lea		VDPDATA,a2
.loadArt
	move.l	(a1)+,(a2)
	dbf		d0,	.loadArt
	rts
	
ArtLists:
	dc.w	.list1-ArtLists
	dc.w	.list2-ArtLists
	
.list1:
	ARTLIST	art,	art_end,	0
	ARTLIST	redart,	redart_end,	$4000
	ARTLIST_END
	
.list2:
	ARTLIST	redart,	redart_end,	0
	ARTLIST_END