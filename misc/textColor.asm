;
; Demo displaying a color-wash effect.
; Uses raster interrupt.
;

!to "textcolor.prg", cbm

; launch routine
*=$0801
!byte $0c, $08, $0a, $00, $9e, $20, $38, $31, $39, $32


; main menu color wash data
color !byte $09,$09,$02,$02,$08
      !byte $08,$0a,$0a,$0f,$0f
      !byte $07,$07,$01,$01,$01
      !byte $01,$01,$01,$01,$01
      !byte $01,$01,$01,$01,$01
      !byte $01,$01,$01,$07,$07
      !byte $0f,$0f,$0a,$0a,$08
      !byte $08,$02,$02,$09,$09

color2 !byte $09,$09,$02,$02,$08
       !byte $08,$0a,$0a,$0f,$0f
       !byte $07,$07,$01,$01,$01
       !byte $01,$01,$01,$01,$01
       !byte $01,$01,$01,$01,$01
       !byte $01,$01,$01,$07,$07
       !byte $0f,$0f,$0a,$0a,$08
       !byte $08,$02,$02,$09,$09

Text   !scr "Hello colorful world!"

; ----- MAIN PROGRAM -----
*=$2000
.init:
      jsr startMainScreen
.initInterrupt:
      sei
      lda #$7f

      sta $dc0d
      sta $dd0d

      lda #$01
      sta $d01a

      ldx #$1b     ; text mode
      lda #$08     ; single color text
      ldy #$16     ; lowercase mode ($14 for uppercase)
      stx $d011
      sta $d016
      sty $d018

      lda #<updateIRQ
      ldx #>updateIRQ
      sta $0314
      stx $0315

      ldy #$ff   ; line to trigger interrupt
      sty $d012

      lda $dc0d
      lda $dd0d
      asl $d019
      cli
.mainLoop:
      jmp .mainLoop

      rts


; ----- START MAIN MENU -----
startMainScreen:
      lda $d011   ; reset screen scroll
      and #247
      sta $d011

      lda #$00     ; disable sprites in main screen
      sta $d015

      jsr clearScreen

      ldx #0
      lda #$f    ; gray color - main text
.drawTitle:
      lda Text, x
      sta $0481,x
      inx
      cpx #21
      bne .drawTitle

      ldx #0
      rts


; ----- MAIN UPDATE SUBROUTINE (called on raster irq) -----
updateIRQ:
      asl $d019

      jsr colorEffect
      jmp $ea81


; ----- MAIN MENU COLOR EFFECT -----
colorEffect:
    lda color
    sta color + $28
    ldx #$00
    sta $daf5, x
.cycle1:
    lda color + 1, x
    sta color, x
    sta $d881, x
    inx
    cpx #$28
    bne .cycle1

    lda color2 + $28
    sta color2
    ldx #$28
.cycle2:
    lda color2 - 1, x
    sta color2, x
    sta $d9f5, x
    dex
    bne .cycle2
    rts

; ----- CLEAR SCREEN -----
clearScreen:
      lda #$00
      tax
      sta $d020
      sta $d021
      lda #$20
.clrLoop:
      sta $0400, x
      sta $0500, x
      sta $0600, x
      sta $0700, x  ; be careful here - clearing all bytes starting from $0700 will corrupt sprite data
      dex
      bne .clrLoop

; use this code to clear the $0700 screen region skipping last 8 bytes (sprite pointers)
;      ldx #$f7
;clrLastSegment:
;      sta $0700, x
;      dex
;      bne clrLastSegment
      rts
