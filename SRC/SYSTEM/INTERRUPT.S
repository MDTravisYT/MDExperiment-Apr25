VInt:
    movem.l d0-a6,-(sp)
	move.b	#0,	VSWAIT
	JSR		READJOYPADS
    movem.l (sp)+,d0-a6
HInt:
	rte