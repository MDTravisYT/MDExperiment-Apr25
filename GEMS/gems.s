;
;    File:          Gems.a - Version 2.5 for MicroTec 5/21/92
;
;    Contains: The library routines and includes for Gems data.
;
;    Written by:    Burt Sloane & Jonathan L. Miller
;
;    Copyright:     1991,1992 by Sega of America, Inc., all rights reserved.
;
;    Change History:
;         5/21/92 JLM Update for 2.5 - unchaged from 2.2
;         3/5/92 JLM Update for 2.2 - new z80 mem map, plus fixed dmastart
;         11/19/91 BAS Update for 2.0, several routines didnt disable ints
;
;    To Do:
;
;
;
;     OPT  E,CASE

;     XDEF _gemsdmastart
;     XDEF _gemsdmaend
;     XDEF _gemsholdz80
;     XDEF _gemsreleasez80
;     XDEF _gemsloadz80
;     XDEF _gemsstartz80
;     XDEF _gemsputcbyte
;     XDEF _gemsputptr
;     XDEF _gemsinit
;     XDEF _gemsstartsong
;     XDEF _gemsstopsong
;     XDEF _gemssettempo
;     XDEF _gemspauseall
;     XDEF _gemsresumeall
;     XDEF _gemsstopall
;     XDEF _gemslockchannel
;     XDEF _gemsunlockchannel
;     XDEF _gemsprogchange
;     XDEF _gemsnoteon
;     XDEF _gemsnoteoff
;     XDEF _gemssetprio
;     XDEF _gemspitchbend
;     XDEF _gemssetenv
;     XDEF _gemsretrigenv
;     XDEF _gemssustain
;     XDEF _gemsmute
;     XDEF _gemsstorembox
;     XDEF _gemsreadmbox
;     XDEF _gemssamprate
;
;     XDEF _patchbank
;     XDEF _envbank
;     XDEF _seqbank
;     XDEF _sampbank


; N.B.  in routines in this file, a0 and d0 are freely trashed


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DATA INCLUDES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_Z80CODE
     include   GEMS/z80.asm
_Z80END
;     align     2
	even

_patchbank
     include   GEMS/pbank.asm
_envbank
     include   GEMS/mbank.asm
_seqbank
     include GEMS/sbank.asm
_sampbank
     include GEMS/dbank.asm

;     align     2
	even


BUSREQ         EQU  $A11100             ; Z80 bus request control register
BUSRES         EQU  $A11200             ; Z80 reset control register
Z80RAM         EQU  $A00000             ; Z80 RAM in 68k addr space
Z80DMABLOCK    EQU  $A01b20             ; Z80 can't read 68k space if set
Z80DMAUNSAFE   EQU  $A01b21             ; Z80 might be reading 68k space if set
Z80MBOXBASE    EQU  $A01b22             ; Z80 mailbox base addr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Z80 CONTROL ROUTINES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
; gemsdmastart - tell the z80 we want to do dma
;

_gemsdmastart


          move.w    sr,-(SP)
          or.w #$0700,sr      ; disable ints

dsretry
          move.w    #$100,BUSREQ        ; Z80 bus request on
dslp      btst.b    #0,BUSREQ      ; spin on bus grant
          bne.s     dslp

          move.b    #1,Z80DMABLOCK      ; set dma block semaphore
          move.b    Z80DMAUNSAFE,d0          ; get unsafe flag

          move.w    #$0,BUSREQ          ; Z80 bus request off

          tst.b     d0             ; was it safe?
          beq.s     dsok           ; yes
          moveq     #68,d0              ; no, wait > 59 microsecs (ms;8[states/ms]/10[dbra])
dswait         dbra d0,dswait      ; wait
          bra.s     dsretry
dsok

          move.w    (sp)+,sr
          rts

;
; gemsdmaend - tell the z80 we're done with dma
;

_gemsdmaend

          move.w    sr,-(SP)
          or.w #$0700,sr      ; disable ints

          jsr  _gemsholdz80
          move.b    #0,Z80DMABLOCK
          jsr  _gemsreleasez80

          move.w    (sp)+,sr
          rts

;
; gemsholdz80 - take the z80 bus
;

_gemsholdz80

          move.w    #$100,BUSREQ        ; Z80 bus request on
hzlp      btst.b    #0,BUSREQ      ; spin on bus grant
          bne.s     hzlp

          rts

;
; gemsreleasez80 - release the z80 bus
;

_gemsreleasez80

          move.w    #$0,BUSREQ          ; Z80 bus request off

          rts

;
; gemsloadz80 - bus request the z80 and download the code between Z80CODE and Z80END
;

_gemsloadz80
          move.l    a1,-(sp)
          move.w    sr,-(SP)
          or.w #$0700,sr      ; disable ints

          move.w    #$100,BUSRES        ; Z80 bus reset off
          jsr  _gemsholdz80

          lea  _Z80CODE,a0         ; copy from 68k to z80 addr space
          lea  _Z80END,a1
          move.l    a1,d0
          sub.l     a0,d0
          subq #1,d0               ; d0 is # of byte to copy - 1 (for dbra)
          lea  Z80RAM,a1
lzlp1          move.b    (a0)+,(a1)+
          dbra d0,lzlp1

lzlp2          move.b    #0,(a1)+       ; zero fill remainder of 8k block
          cmpa.l    #(Z80RAM+$2000),a1
          bne.s     lzlp2

          move.w    (sp)+,sr
          move.l    (sp)+,a1
          rts

;
; gemsstartz80 - release the z80 bus and reset the z80 (use after loadz80)
;

_gemsstartz80

          move.w    sr,-(SP)
          or.w #$0700,sr      ; disable ints

          move.w    #$0,BUSRES          ; Z80 bus reset on (assumes buss rquest on)
          move.l    #15,d0              ; a loop > 26 uS
szlp      subq.l    #1,d0
          bne.s     szlp
          move.w    #$0,BUSREQ          ; Z80 bus request off
          move.w    #$100,BUSRES        ; Z80 bus reset off

          move.w    (sp)+,sr
          rts

;
; stdsetup - setup these regs:
;  d1 - the old value of wptr
;  a0 - Z80RAM+$36(wptr)
;  a1 - Z80RAM+$1B40(fifo)
; also save the sr, turns off ints, and holds the z80
;
stdsetup
          move.l    (sp)+,a0       ; get the return addr
          link a6,#0               ; set up the link
          movem.l   d1/a1,-(sp)         ; save some regs
          move.w    sr,-(SP)

          move.l    a0,-(sp)       ; push the return addr

          lea  Z80RAM+$36,a0       ; a0 points to wptr
          lea  Z80RAM+$1B40,a1          ; a1 points to fifo

          or.w #$0700,sr      ; disable ints

          move.w    #$100,BUSREQ        ; Z80 bus request on
sslp      btst.b    #0,BUSREQ      ; spin on bus grant
          bne.s     sslp

          move.b    (a0),d1             ; d1 is write index into fifo
          ext.w     d1             ; extend to 16 bits

          rts

;
; stdcleanup - clean up after stdsetup - JMP here only!!!
;
stdcleanup
          move.w    #$0,BUSREQ          ; Z80 bus request off
          move.w    (sp)+,sr
          movem.l   (sp)+,d1/a1
          unlk a6
          rts

;
; stdcmdwrite - write a command to the z80(-1, d0), assuming:
;  d0 - the byte
;  d1 - the value of wptr
;  a0 - Z80RAM+$36(wptr)
;  a1 - Z80RAM+$1B40(fifo)
;
stdcmdwrite
          move.b    #-1,0(a1,d1.w)          ; write into fifo

          addq.b    #1,d1               ; increment write index mod 64
          andi.b    #$3F,d1
; fall through to stdwrite

;
; stdwrite - write a byte to the z80, assuming:
;  d0 - the byte
;  d1 - the value of wptr
;  a0 - Z80RAM+$36(wptr)
;  a1 - Z80RAM+$1B40(fifo)
;
stdwrite
          move.b    d0,0(a1,d1.w)      ; write into fifo

          addq.b    #1,d1               ; increment write index mod 64
          andi.b    #$3F,d1
          move.b    d1,(a0)             ; write it back

          rts

;
; gemsputcbyte - write a byte into the z80's incoming command fifo
;
; stack frame after the link:
;    +------------------+
;    +    byte(long)    +  000000bb
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsputcbyte
          jsr  stdsetup

          move.l    8(a6),d0       ; get command byte into d0
          jsr  stdwrite

          jmp  stdcleanup

;
; gemsputptr - utility to send a 24-bit ptr to the z80's incoming command fifo
;
; stack frame after the link:
;    +------------------+
;    +     ptr(long)    +  00pppppp
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsputptr
          jsr  stdsetup

          move.l    8(a6),d0       ; get ptr into d0
          jsr  stdwrite

          asr.l     #8,d0
          jsr  stdwrite

          asr.l     #8,d0
          jsr  stdwrite

          jmp  stdcleanup

;
; gemsinit - initialize the z80 and send pointers to data in 68000 space
;
; stack frame after the link:
;    +------------------+
;    +   sampbankptr    +  00pppppp
;  +20    +------------------+
;    +    seqbankptr    +  00pppppp
;  +16    +------------------+
;    +    envbankptr    +  00pppppp
;  +12    +------------------+
;    +   patchbankptr   +  00pppppp
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsinit
          link a6,#0
          jsr  _gemsloadz80
          jsr  _gemsstartz80

          moveq     #-1,d0
          move.l    d0,-(A7)
          jsr  _gemsputcbyte
          moveq     #11,d0
          move.l    d0,-(A7)
          jsr  _gemsputcbyte

          move.l    8(A6),-(A7)
          jsr  _gemsputptr
          move.l    12(A6),-(A7)
          jsr  _gemsputptr
          move.l    16(A6),-(A7)
          jsr  _gemsputptr
          move.l    20(A6),-(A7)
          jsr  _gemsputptr
          unlk a6

          rts

;
; gemsstartsong - start a song by #
;
; stack frame after the link:
;    +------------------+
;    +   song #(long)   +  000000ss
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsstartsong
          jsr  stdsetup

          moveq     #16,d0

com1arg
          jsr  stdcmdwrite

          move.l    8(A6),d0
          jsr  stdwrite

          jmp  stdcleanup

;
; gemsstopsong - stop a song by #
;
; stack frame after the link:
;    +------------------+
;    +   song #(long)   +  000000ss
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsstopsong
          jsr  stdsetup

          moveq     #18,d0
          bra.s     com1arg

;
; gemssettempo - set tempo
;
; stack frame after the link:
;    +------------------+
;    +   tempo (long)   +  000000tt
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemssettempo
          jsr  stdsetup

          moveq     #5,d0
          bra.s     com1arg

;
; gemspauseall - pause all songs currently running
;
; stack frame after the link:
;    +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemspauseall
          jsr  stdsetup

          moveq     #12,d0
          jsr  stdcmdwrite

          jmp  stdcleanup

;
; gemsresumeall - resume all songs currently paused
;
; stack frame after the link:
;    +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsresumeall
          jsr  stdsetup

          moveq     #13,d0
          jsr  stdcmdwrite

          jmp  stdcleanup


;
; gemsstopall - stop all songs currently playing, reset
;
; stack frame after the link:
;    +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsstopall
          jsr  stdsetup

          moveq     #22,d0
          jsr  stdcmdwrite

          jmp  stdcleanup


;
; gemslockchannel - lock a sound effects channel
;
; stack frame after the link:
;    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemslockchannel
          jsr  stdsetup

          moveq     #28,d0
          bra.s     com1arg

;
; gemsunlockchannel - unlock a sound effects channel
;
; stack frame after the link:
;    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsunlockchannel
          jsr  stdsetup

          moveq     #29,d0
          bra.s     com1arg

;
; gemsprogchange - program change
;
; stack frame after the link:
;    +------------------+
;    +    prog (long)   +  000000pp
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsprogchange
          jsr  stdsetup

          moveq     #2,d0

com2arg
          jsr  stdcmdwrite

          move.l    8(A6),d0
          jsr  stdwrite

          move.l    12(A6),d0
          jsr  stdwrite

          jmp  stdcleanup

;
; gemsnoteon - turn note on
;
; stack frame after the link:
;    +------------------+
;    +    note (long)   +  000000nn
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsnoteon
          jsr  stdsetup

          moveq     #0,d0
          bra.s     com2arg

;
; gemsnoteoff - turn note off
;
; stack frame after the link:
;    +------------------+
;    +    note (long)   +  000000nn
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsnoteoff
          jsr  stdsetup

          moveq     #1,d0
          bra.s     com2arg

;
; gemssetprio - set channel priority
;
; stack frame after the link:
;    +------------------+
;    + priority (long)  +  000000pp
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemssetprio
          jsr  stdsetup

          moveq     #20,d0
          bra.s     com2arg

;
; gemspitchbend - pitch bend
;
; stack frame after the link:
;    +------------------+
;    +  bend amt (long) +  0000bbbb  signed 8-bit frac is # semi-tones
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemspitchbend
          jsr  stdsetup

          moveq     #5,d0
          jsr  stdcmdwrite

          move.l    8(A6),d0
          jsr  stdwrite

          move.l    12(A6),d0
          jsr  stdwrite

          asr.l     #8,d0
          jsr  stdwrite

          jmp  stdcleanup

;
; gemssetenv - connect channel to envelope(trigger it if not in retrig mode)
;
; stack frame after the link:
;    +------------------+
;    +    env (long)    +  000000ee
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemssetenv
          jsr  stdsetup

          moveq     #6,d0
          bra.s     com2arg

;
; gemsretrigenv - turn on retrig mode if val is 80h, off if 0h
;
; stack frame after the link:
;    +------------------+
;    +    val (long)    +  000000vv
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsretrigenv
          jsr  stdsetup

          moveq     #7,d0
          bra     com2arg

;
; gemssustain - turn on sustain mode if val is 80h, off if 0h
;
; stack frame after the link:
;    +------------------+
;    +    val (long)    +  000000vv
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemssustain
          jsr  stdsetup

          moveq     #14,d0
          bra     com2arg

;
; gemsmute - mute song/channel if val is 1, enable if 0
;
; stack frame after the link:
;    +------------------+
;    +    val (long)    +  000000vv
;  +16    +------------------+
;    +  channel (long)  +  000000cc
;  +12    +------------------+
;    +    song (long)   +  000000ss
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsmute
          jsr  stdsetup

          moveq     #23,d0
com3arg
          jsr  stdcmdwrite

          move.l    8(A6),d0
          jsr  stdwrite

          move.l    12(A6),d0
          jsr  stdwrite

          move.l    16(A6),d0
          jsr  stdwrite

          jmp  stdcleanup


;
; gemsstorembox - store val(0..127) in mailbox(0..29)
;
; stack frame after the link:
;    +------------------+
;    +    val (long)    +  000000vv
;  +12    +------------------+
;    +  mailbox (long)  +  000000mm
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemsstorembox

          jsr  stdsetup

          moveq     #27,d0
          bra  com2arg

;
; gemsreadmbox - read a val(0..127) from a mailbox(0..29)
;
; stack frame at the top of the proc:
;    +------------------+
;    +  mailbox (long)  +  000000mm
;  +4     +------------------+
;    +  return address  +
;  a7-> +------------------+
;
; returns value in d0

_gemsreadmbox

          move.w    sr,-(SP)
          or.w #$0700,sr      ; disable ints

          jsr  _gemsholdz80
          moveq     #0,d0
          move.b    11(a7),d0
          lea  Z80MBOXBASE,a0
          move.b    0(a0,d0.w),d0
          jsr  _gemsreleasez80

          move.w    (sp)+,sr
          rts

;
; gemssamprate - set digital playback rate for channel
;  4 = no override, get rate from sample header
;  5 = 10.4 kHz, see docs for other freqs
;
; stack frame after the link:
;    +------------------+
;    +    rate (long)   +  000000rr
;  +12    +------------------+
;    +  channel (long)  +  000000cc
;  +8     +------------------+
;    +  return address  +
;  +4     +------------------+
;    +    previous a6   +
;  a6-> +------------------+

_gemssamprate

          jsr  stdsetup

          moveq     #26,d0
          bra  com2arg



