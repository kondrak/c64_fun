;
; Demonstration of how to play a simple sound (on fire press).
; Uses raster interrupt.
;

!to "playsound.prg", cbm

; launch routine
*=$0801
!byte $0c, $08, $0a, $00, $9e, $20, $38, $31, $39, $32

deltaX      !byte $0   ; dx for joystick movement ( -1 - left, 1 - right, 0 - none)
deltaY      !byte $0   ; dy for joystick movement ( -1 - up, 1 - down - 0 none; not really used, but let's keep it)
firePressed !byte $1   ; 1 - not pressed; 0 - pressed
fireHandled !byte $0   ; 1 - yes, 0 - no

InfoText     !scr "press fire to play sound"

; ----- MAIN PROGRAM -----
*=$2000

.initSound:
      lda #0
      sta $d400
      lda #10
      sta $d401
      lda #04
      sta $d405
      lda #$19
      sta $d406
      lda #15
      sta $d418
.drawTitle:
      lda InfoText, x
      sta $0688,x
      inx
      cpx #24
      bne .drawTitle
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

      ldy #$ff   ; line to trigger interrupt
      sty $d012

      lda $dc0d
      lda $dd0d
      asl $d019
      cli
.mainLoop:
      jmp .mainLoop
      rts


; ----- PLAY SOUND -----
playExplosionSound:
      ldx #5
      stx $d401
      lda #$8
      sta $d406
      lda #$0A
      sta $d405

      lda #0
      sta $d404

      lda #%10000001     ; use noise for sound playback
      sta $d404
      rts


; ----- MAIN UPDATE SUBROUTINE (called on raster irq) -----
updateIRQ:
      asl $d019

      jsr handleJoystick

      ldx firePressed
      beq .handleFire
      ldx #0
      stx fireHandled
      beq .updateIrqEnd
.handleFire:
      ldx fireHandled
      bne .updateIrqEnd
      jsr playExplosionSound
.updateIrqEnd:
      jmp $ea81


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