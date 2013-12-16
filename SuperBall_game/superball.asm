;  SUPERBALL C64
;  A Commodore 64 port of a popular SAT-1 TV show game "Superball" from early 1990s
; (c) 2013 Krzysztof Kondrak
; --------------------------------

!to "superball.prg", cbm

*=$0801
!byte $0c, $08, $0a, $00, $9e, $20, $38, $31, $39, $32

; ----- GAME DATA -----
deltaX      !byte $0   ; dx for joystick movement ( -1 - left, 1 - right, 0 - none)
deltaY      !byte $0   ; dy for joystick movement ( -1 - up, 1 - down - 0 none; not really used, but let's keep it)
firePressed !byte $1   ; 1 - not pressed; 0 - pressed
fireHandled !byte $0   ; 1 - yes, 0 - no

unitsPassed       !byte $0
tensPassed        !byte $0
hundredsPassed    !byte $0
thousandsPassed   !byte $0
frameCounter      !byte $0
playMoveSoundNow  !byte $0
playBeepBoop      !byte $0  ; 0 - beep, 1 - boop, 2 - neither
beepBoopFreq      !byte $0
currentState      !byte $0  ; game state
ballMoveDir       !byte $0  ; 0 - stationary, 1 - left, 2 - right
currBallFrameTime !byte $0  ; counter used for animating the ball
enemyCount        !byte $2  ; start with 2 to speed up level 1
enemySpeed        !byte $1
currentLevel      !byte $0  ; level indexing starts from 0, not 1

; starting from digit 0 to 9
numberSprites !byte $c5, $c6, $c7, $c8, $c9, $cA, $cB, $cC, $cD, $cE, $c5

; horizontal positions on the grid
enemyPositions !byte $77, $88, $99, $88, $CC, $BB, $CC, $DD

; grid line graphics data
gridLine !byte $6b, $e0, $40, $5b, $40
         !byte $5b, $40, $5b, $40, $5b
         !byte $40, $5b, $40, $5b, $40
         !byte $5b, $40, $5b, $40, $e0

; a border color - grid color byte pairs
gridColor !word $0E0C, $0A0E, $020C, $080F, $050A, $0D0B, $040F, $080C, $050B

TitleTxt     !scr "*** SUPERBALL C64 ***"
AuthorTxt    !scr "2013  Krzysztof Kondrak"
Line1Txt     !scr "Roll your ball but watch ahead,"
Line2Txt     !scr "Nasty Disklets want you DEAD!"
GoodLuckTxt  !scr "!!! GOOD LUCK !!!"
PressFireTxt !scr "PRESS FIRE"
GameOverTxt  !scr "Final Score:"

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


BALL_ANIM_DELAY     = 7   ; delay between ball frames - decrease to make it faster
GRID_WIDTH          = 19
BEEP_BOOP_FREQUENCY = 4   ; initial frequency of the beep-boop sound

STATE_MAINSCREEN = 0
STATE_INGAME     = 1
STATE_GAMEOVER   = 2

; ----- MACROS -----
; hardcopy screen row
!macro scrollMacro .t {
      ldx #GRID_WIDTH
.m1
      lda $409 + (.t - 1) * 40, x
      sta $409 + .t * 40, x
      dex
      bne .m1
}

; set proper colors to grid row characters
!macro gridColorMacro .t {
      lda currentLevel
      asl
      tax
      lda gridColor + 1, x

      sta $d80A + .t * 40
      sta $d81C + .t * 40

      lda gridColor, x
      ldx #17
.m2
      sta $d80A + .t * 40, x
      dex
      bne .m2
}


; ----- MAIN PROGRAM -----
*=$2000

.init:
      ; manually remove all characters first
      lda #$20
      ldx #0
.zeroScrLoop:
      sta $0400, x
      sta $0500, x
      sta $0600, x
      sta $0700, x
      dex
      bne .zeroScrLoop
      
      jsr clearScreen
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
.initSprites:
      lda #%01111111     ; use sprites 0 - 7
      sta $d015
      sta $d01c          ; enable multicolor

      ; scale the sprite containing level counter
      lda #%00010000
      sta $d01d
      sta $d017

      ; multicolor settings
      lda #$0a
      sta $d025
      lda #$0d
      sta $d026

      ; sprite 0 - ball
      lda #$AA     ; set coordinates
      sta $d000
      lda #$DD
      sta $d001

      lda #$c0     ; set sprite image
      sta $07f8

      lda #$9      ; set sprite color
      sta $d027

      ; sprite 1 - disklet (enemy)
      lda #$c4     ; set sprite image
      sta $07f9

      lda #$7      ; set sprite color
      sta $d028

      ; sprite 2 - score digit
      lda #$07     ; set coordinates
      sta $d004
      lda #$44
      sta $d005

      lda #$c5     ; set sprite image
      sta $07fA

      ; sprite 3 - score digit
      lda #$17     ; set coordinates
      sta $d006
      lda #$44
      sta $d007

      lda #$c5     ; set sprite image
      sta $07fB

       ; sprite 4 - level counter
      lda #$17    ; set coordinates
      sta $d008
      lda #$AA
      sta $d009

      lda #$c6    ; set sprite image
      sta $07fC

       ; sprite 5 - score digit
      lda #$27    ; set coordinates
      sta $d00A
      lda #$44
      sta $d00B

      lda #$c5    ; set sprite image
      sta $07fD

       ; sprite 6 - score digit
      lda #$37    ; set coordinates
      sta $d00C
      lda #$44
      sta $d00D

      lda #$c5    ; set sprite image
      sta $07fE

      ; set color for digit sprites
      lda #$d
      sta $d029
      sta $d02A
      sta $d02B
      sta $d02C
      sta $d02D

      ; set the x "bit flip" for digit sprites
      lda #%01111100
      sta $d010

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
      ldy #$16     ; lowercase mode
      stx $d011
      sta $d016
      sty $d018

      lda #<updateIRQ
      ldx #>updateIRQ
      sta $0314
      stx $0315

      ldy #$f4   ; line to trigger interrupt
      sty $d012

      lda $dc0d
      lda $dd0d
      asl $d019
      cli
.mainLoop:
      lda $d01e         ; ball collided with enemy?
      and #01
      bne .ballCollided
      jmp .mainLoop
.ballCollided:
      jsr playExplosionSound
      jsr startGameOver

      jmp .mainLoop
      rts


; ----- START MAIN MENU -----
startMainScreen:
      lda $d011   ; reset screen scroll
      and #247
      sta $d011

      lda #$00     ; disable sprites in main screen
      sta $d015

      lda #STATE_MAINSCREEN
      sta currentState

      jsr clearScreen

      ldx #0
      lda #$f    ; gray color - main text
.resetColors1:
      sta $d800, x
      sta $d900, x
      dex
      bne .resetColors1

      ldx #0     ; white color - PRESS FIRE
      lda #1
.resetColors2:
      sta $dA00, x
      sta $dB00, x
      dex
      bne .resetColors2

      ldx #0
.drawTitle:
      lda TitleTxt, x
      sta $0481,x
      inx
      cpx #21
      bne .drawTitle

      ldx #0
.drawAuthor:
      lda AuthorTxt, x
      sta $0520, x
      inx
      cpx #23
      bne .drawAuthor

      ldx #0
.drawLine1:
      lda Line1Txt, x
      sta $0595, x
      inx
      cpx #31
      bne .drawLine1

      ldx #0
.drawLine2:
      lda Line2Txt, x
      sta $05be, x
      inx
      cpx #29
      bne .drawLine2

      ldx #0
.drawPressFire:
      lda PressFireTxt, x
      sta $0707, x
      inx
      cpx #10
      bne .drawPressFire
      rts


; ----- START INGAME -----
startIngame:
      lda #STATE_INGAME
      sta currentState

      jsr clearScreen

      ; reset the x "bit flip" for digits and coordinates
      lda $d010
      ora #%01101100
      sta $d010

      lda #$07
      sta $d004

      lda #$17
      sta $d006

      lda #$27
      sta $d00A

      lda #$37
      sta $d00C

      lda #$44
      sta $d005
      sta $d007
      sta $d00B
      sta $d00D

      ; re-enable sprites
      lda #$7f
      sta $d015

      jsr resetIngame

      ldx #00
.drawGoodLuck:
      lda GoodLuckTxt, x
      sta $045b, x
      inx
      cpx #17
      bne .drawGoodLuck
      rts


; ----- ENTER GAME OVER STATE -----
startGameOver:
      lda #STATE_GAMEOVER
      sta currentState

      jsr clearScreen
      ldx #00
.drawGameOver:
      lda GameOverTxt, x
      sta $054e, x
      inx
      cpx #12
      bne .drawGameOver

      lda $d015
      and #%01101100
      sta $d015

      ; disable x "bit flip" for digit sprites
      lda $d010
      and #%10010011
      sta $d010

      lda #$94
      sta $d004

      lda #$A4
      sta $d006

      lda #$B4
      sta $d00A

      lda #$C4
      sta $d00C

      lda #$84
      sta $d005
      sta $d007
      sta $d00B
      sta $d00D
      rts


; ----- PLAY SOUND SUBROUTINES -----
playMoveSound:
      ldx #50
      stx $d401
      lda #$08
      sta $d406
      lda #$50
      sta $d405

      lda #0
      sta $d404

      lda #%10000001
      sta $d404
      rts

playLevelUpSound:
      ldx #40
      stx $d408
      lda #$8
      sta $d40D
      lda #$0A
      sta $d40C

      lda #0
      sta $d40B

      lda #%00010001
      sta $d40B
      rts

playBeep:
      inc beepBoopFreq
      jsr playBoop
      dec beepBoopFreq
      rts

playBoop:
      ldx beepBoopFreq
      stx $d40F
      lda #$8
      sta $d414
      lda #$08
      sta $d413

      lda #0
      sta $d412

      lda #%00010001
      sta $d412
      rts

playExplosionSound:
      ldx #5
      stx $d401
      lda #$8
      sta $d406
      lda #$0A
      sta $d405

      lda #0
      sta $d404

      lda #%10000001
      sta $d404
      rts


; ----- RESET INGAME -----
resetIngame:
      lda #0
      sta currentLevel
      sta unitsPassed
      sta tensPassed
      sta hundredsPassed
      sta thousandsPassed
      sta frameCounter
      sta ballMoveDir
      sta enemySpeed
      sta playBeepBoop

      lda #2
      sta enemyCount
      
      lda #$ff
      sta currentLevel
      jsr increaseLevel

      lda #BALL_ANIM_DELAY
      sta currBallFrameTime

      lda #BEEP_BOOP_FREQUENCY
      sta beepBoopFreq

      ; randomize enemy position
      lda #$00
      sta $d002
      sta $d003

      ; reset ball position
      lda #$AA
      sta $d000

      lda numberSprites ; reset counter sprites
      sta $07fA
      sta $07fB
      sta $07fD
      sta $07fE

      !for gridRow, 25 {
         +gridColorMacro gridRow-1
      }

      rts


; ----- INCREASE GAME LEVEL -----
increaseLevel:
      lda enemySpeed
      cmp #9
      bne .incLvl
      rts
.incLvl:
      jsr playLevelUpSound
      inc enemySpeed
      inc currentLevel
      inc beepBoopFreq

      ldx enemySpeed
      lda numberSprites, x
      sta $07fc

      !for gridRow, 25 {
         +gridColorMacro gridRow-1
      }

      rts


; ----- UPDATE THE ENEMY -----
updateEnemies:
      ldx enemySpeed
.updatePosLoop
      inc $d003
      dex
      bne .updatePosLoop
      lda $d003

      cmp #$F6
      bcc .updateEnemiesEnd

      inc $d028   ; increase color idx
.updateEnemyPos:
      lda $DC05
      eor $DC04
      and #7
      tax
      lda enemyPositions, x
      sta $d002

      lda #$00
      sta $d003

      inc enemyCount
      lda enemyCount
      cmp #10
      bne .updateEnemiesEnd

      lda #0
      sta enemyCount
      jsr increaseLevel
.updateEnemiesEnd:
      rts


; ----- SCROLL INGAME GRID -----
scrollDownGrid:
      !for gridRow, 24 {
         +scrollMacro 25 - gridRow
      }

      ldx #40
      lda #$20
.clearLine:
      sta $03ff, x
      dex
      bne .clearLine

      ldx #GRID_WIDTH
.drawGrid:
      lda gridLine, x
      sta $409, x
      dex
      bne .drawGrid
      rts


; ----- MAIN UPDATE SUBROUTINE (called on raster irq) -----
updateIRQ:
      asl $d019

      jsr handleJoystick

      lda currentState
      ldx firePressed
      beq .handleFire

      ldx #$0
      stx fireHandled
      jmp .checkState
.handleFire:
      ldx fireHandled
      bne .checkState

      ldx #$01
      stx fireHandled
      cmp #STATE_MAINSCREEN
      beq .startGame
      cmp #STATE_GAMEOVER
      beq .gotoMainScreen
      jmp .checkState
.startGame:
      jsr startIngame
      jmp .updateCtrlEnd
.gotoMainScreen:
      jsr startMainScreen
      jmp .updateCtrlEnd
.checkState:
      cmp #STATE_INGAME
      beq .updateIngame
      cmp #STATE_MAINSCREEN
      beq .updateMainScreen
      jmp .updateCtrlEnd
.updateMainScreen:
      jsr colorEffect
      jmp .updateCtrlEnd
.updateIngame:
      jsr updateEnemies
      jsr updateScore
      jsr moveBall

      lda $d011
      and #7
      tax
      inx
      cpx #8
      beq .updateScroll
      inc $d011

      jmp .updateBallAnim
.updateScroll:
      lda $d011
      and #247
      sta $d011

      lda $d011
      and #248
      sta $d011

      jsr scrollDownGrid
.updateBallAnim:
      dec currBallFrameTime

      bne .updateCtrlEnd

      lda #BALL_ANIM_DELAY
      sta currBallFrameTime
      lda $07f8
      tax
      inx
      cpx #$c4     ; flip ball frame now?
      bne .storeNewFrame
      ldx #$c0
.storeNewFrame:
      stx $07f8
.updateCtrlEnd:
      jmp $ea81


; ----- UPDATE SCORE -----
updateScore:
      inc frameCounter
      lda frameCounter
      cmp #6               ; update score every 6 frames
      bne .updateScoreDone
      inc unitsPassed
      ldx unitsPassed

      ; by default don't play any sounds - flag will be set if necessary
      lda playBeepBoop
      ora #2
      sta playBeepBoop

      cpx #10
      bne .updateUnitsSprite
      lda playBeepBoop
      eor #3
      sta playBeepBoop
      inc tensPassed
      lda #0
      sta unitsPassed
.updateUnitsSprite:
      lda numberSprites, x
      sta $07fE

      lda #0
      sta frameCounter
      ldx tensPassed
.updateTensSprite:
      lda numberSprites, x
      sta $07fD

      cpx #10
      bne .updateScoreDone
      inc hundredsPassed
      lda #0
      sta tensPassed
      ldx hundredsPassed
.updateHundredsSprite:
      lda numberSprites, x
      sta $07fB

      cpx #10
      bne .updateScoreDone
      inc thousandsPassed
      lda #0
      sta hundredsPassed
      ldx thousandsPassed
.updateThousandsSprite:
      lda numberSprites, x
      sta $07fA

      cpx #10
      bne .updateScoreDone
      lda #0
      sta thousandsPassed
.updateScoreDone:
      lda playBeepBoop
      cmp #0
      beq .beep
      cmp #1
      beq .boop
      jmp .updateScoreExit
.beep:
      jsr playBeep
      jmp .updateScoreExit
.boop:
      jsr playBoop
.updateScoreExit:
      rts


;----- MOVE THE PLAYER -----
moveBall:
      lda ballMoveDir
      cmp #$01
      beq .checkHorizontalRight
      cmp #$ff
      beq .checkHorizontalLeft
      jmp .exitMoveProc
.checkHorizontalRight:
      lda $d000  ; limit on movement right
      cmp #$DD
      bpl .exitMoveProc
      inc $d000         ; update horizontal position
      bne .exitMoveProc
      jsr flipPosBitX
      jmp .exitMoveProc
.checkHorizontalLeft:
      lda $d000  ; limit on movement left
      cmp #$74
      bmi .exitMoveProc

      lda $d000     ; update horizontal position
      bne .decX
      jsr flipPosBitX
.decX:
      dec $d000
.exitMoveProc:
      ldx playMoveSoundNow
      cpx #$1
      bne .moveBallEnd
      jsr playMoveSound
.moveBallEnd:
      lda #$0
      sta playMoveSoundNow
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

      ; remember move direction for constant ball movement
      cpx #$01
      beq .storeMoveDir
      cpx #$ff
      beq .storeMoveDir
      jmp .handleJoyEnd
.storeMoveDir:
      cpx ballMoveDir
      beq .store
      lda #$1
      sta playMoveSoundNow
.store:
      stx ballMoveDir
.handleJoyEnd:
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
      dex
      bne .clrLoop

      ; clear the $0700 screen area skipping last 8 bytes (sprite pointers)
      ldx #$f7
.clrLastSegment:
      sta $0700, x
      dex
      bne .clrLastSegment
      rts


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

    
; ---- SPRITE DATA -----
*=$3000
!bin "superball.spr" 