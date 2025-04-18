VInt:
	move.b	#0,	VSWAIT
	JSR		READJOYPADS
HInt:
	rte