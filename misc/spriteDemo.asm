;
; Demo displaying a single sprite and handling joystick actions.
; Uses raster interrupt.
;

!to "spritedemo.prg", cbm

; launch routine
*=$0801
!byte $0c, $08, $0a, $00, $9e, $20, $38, $31, $39, $32

deltaX      !byte $0   ; dx for joystick movement ( -1 - left, 1 - right, 0 - none)
deltaY      !byte $0   ; dy for joystick movement ( -1 - up, 1 - down, 0 - none)
firePressed !byte $1   ; 1 - not pressed; 0 - pressed


; ----- MAIN PROGRAM -----
*=$2000

.init:
      jsr clearScreen
.initSprites:
      lda #1
      sta $d015
      sta $d01c          ; enable multicolor

      ; multicolor settings
      lda #$0A
      sta $d025
      lda #$07
      sta $d026

      ; sprite 0 setup
      lda #$AA      ; set coordinates
      sta $d000
      lda #$88
      sta $d001

      lda #$c0      ; set sprite image
      sta $07f8

      lda #$05      ; set sprite color
      sta $d027
.initInterrupt:
      sei
      lda #$7f

      sta $dc0d
      sta $dd0d

      lda #$01
      sta $d01a

      ldx #$1b     ; text mode
      lda #$08     ; single color text
      ldy #$14     ; uppercase text ($16 for lowercase)
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



; ----- MAIN UPDATE SUBROUTINE (called on raster irq) -----
updateIRQ:
      asl $d019
      jsr handleJoystick

      lda firePressed
      cmp #$1
      beq .move
      inc $d020      ; change border color on fire press
.move:
      jsr moveSprite

      jmp $ea81


;----- MOVE SPRITE -----
moveSprite:
      lda deltaX
      cmp #$01
      beq .checkHorizontalRight
      cmp #$ff
      beq .checkHorizontalLeft
      jmp .checkVertical
.checkHorizontalRight:
      inc $d000
      bne .checkVertical
      jsr flipPosBitX
      jmp .checkVertical
.checkHorizontalLeft:
      lda $d000
      bne .decX
      jsr flipPosBitX
.decX:
      dec $d000
.checkVertical:
      lda $d001
      clc
      adc deltaY
      sta $d001
.exitMoveProc:
      rts


; ----- SUBROUTINE FOR FLIPPING X DIR REGISTER -----
flipPosBitX:
      lda $d010
      eor #$01
      sta $d010
      rts


; ----- HANDLE JOYSTICK (PORT 2) -----
handleJoystick:
      lda $dc00     ; get port 2 input
      ldy #0
      ldx #0
      lsr
      bcs .hj0
      dey
.hj0:
      lsr
      bcs .hj1
      iny
.hj1:
      lsr
      bcs .hj2
      dex
.hj2:
      lsr
      bcs .hj3
      inx
.hj3:
      lsr
      stx deltaX
      sty deltaY
      lda #$0
      bcc .storeFire   ; fire information stored in carry flag
      lda #$1
.storeFire:
      sta firePressed
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


; ---- SPRITE DATA -----
*=$3000
!bin "spritedemo.spr" 