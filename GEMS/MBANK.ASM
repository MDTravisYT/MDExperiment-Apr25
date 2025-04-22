;
; Modulator Offset Table
;

	dc.b	$04,$00		; Offset to modulator #0: 4
	dc.b	$0D,$00		; Offset to modulator #1: 13
;
; Modulator Data
;

; Modulator 0 "jump up": Pitch
	dc.b	$00,$00			; initial value = 0
	dc.b	$18,$2C,$01		; len = 24, slope = 300
	dc.b	$43,$50,$FB		; len = 67, slope = -1200
	dc.b	0
; Modulator 1 "weapon": Pitch
	dc.b	$64,$00			; initial value = 100
	dc.b	$02,$C8,$00		; len = 2, slope = 200
	dc.b	$27,$38,$FF		; len = 39, slope = -200
	dc.b	0
