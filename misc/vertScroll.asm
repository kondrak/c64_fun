;
; Demo displaying vertical screen (text) scrolling effect.
; Uses raster interrupt.
; You'll notice that at some point the scroll becomes jittery when scrolling down - this is because
; we have to copy all lines one by one which is quite expensive. For better performance,
; make sure to only scroll necessary regions of the screen instead of every single character. You can
; (and most likely will have to) fiddle with proper raster line to trigger the irq which can reduce the jitter.
;

; Use this variable to determine scroll direction
SCROLL_DIRECTION = 1 ; 0 - down, 1 - up

!to "vertscroll.prg", cbm

*=$0801
!byte $0c, $08, $0a, $00, $9e, $20, $38, $31, $39, $32

LINE_WIDTH = 40

; helper macro copying line contents
!macro scrollDownMacro .t {
      ldx #LINE_WIDTH
.m1
      lda $3FF + (.t - 1) * 40, x
      sta $3FF + .t * 40, x
      dex
      bne .m1
}


; ----- MAIN PROGRAM -----
*=$2000
.initInterrupt:
      sei
      lda #$7f

      sta $dc0d
      sta $dd0d

      lda #$01
      sta $d01a

      ldx #$1b     ; text mode
      lda #$08     ; single color text
      ldy #$14     ; uppercase mode ($16 for lowercase)
      stx $d011
      sta $d016
      sty $d018

      lda #<updateIRQ
      ldx #>updateIRQ
      sta $0314
      stx $0315

      ldy #$f6   ; line to trigger interrupt
      sty $d012

      lda $dc0d
      lda $dd0d
      asl $d019
      cli
.mainLoop:
      jmp .mainLoop

      rts


; ----- MAIN UPDATE SUBROUTINE (called on raster irq) -----
updateIRQ:
      asl $d019

      ldx #SCROLL_DIRECTION
      cpx #$1
      beq .up
      jmp .down
.up:
      jsr scrollUp
      jmp .updateEnd
.down:
      jsr scrollDown

.updateEnd:
      jmp $ea81


; ----- SCROLL UP -----
scrollUp:
      lda $d011
      and #7
      tax
      dex
      bmi .updateScrollUp
      dec $d011
      jmp .scrollUpExit
.updateScrollUp:
      lda $d011
      and #247
      sta $d011

      lda $d011
      and #248
      ora #7
      sta $d011
      ldx #0
      
; in this case we can simply copy each row disregarding what's above
.scrollLoop:
      lda $0400 + 40, x
      sta $0400, x
      inx
      bne .scrollLoop
.scrollLoop2:
      lda $0500 + 40, x
      sta $0500, x
      inx
      bne .scrollLoop2
.scrollLoop3:
      lda $0600 + 40, x
      sta $0600, x
      inx
      bne .scrollLoop3
.scrollLoop4:
      lda $0700 + 40, x
      sta $0700, x
      inx
      bne .scrollLoop4
.scrollUpExit:
      rts


; ----- SCROLL DOWN -----
scrollDown:
      lda $d011
      and #7
      tax
      inx
      cpx #8
      beq .updateScrollDown
      inc $d011
      jmp .scrollDownExit
.updateScrollDown:
      lda $d011
      and #247
      sta $d011

      lda $d011
      and #248
      sta $d011

      !for gridRow, 24 {
         +scrollDownMacro 25 - gridRow
      }
      
.scrollDownExit:
      rts