;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "errno.inc"
;.include "fcntl.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export external_command

.importzp pfac
.import fn_message_cmnd

.import binstr

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short ptr

	.segment "DATA"
;		unsigned char save_scr[5]
;		unsigned char stdout[80]

	.segment "RODATA"
;		submit_line:
;			.asciiz	"strerr                       "
;			.asciiz	"dbaserr -q 0,    /a/dbase.msg"
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	A: N° erreur
;	X: offset vers le premier caractère non ' '
;
; Sortie:
;	C: 0->Ok, 1->Erreur
; Variables:
;       Modifiées:
;               save_x
;		errorlevel
;       Utilisées:
;               submit_line
; Sous-routines:
;       XEXEC
;----------------------------------------------------------------------
.proc external_command
;		stx	save_x
		sta	pfac
		lda	#$00
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3

		; Efface la dernière valeur utilisée
		lda	#' '
		sta	fn_message_cmnd+13
		sta	fn_message_cmnd+14
		sta	fn_message_cmnd+15

		lda	#$00
		ldx	#<pfac
		ldy	#>pfac
		jsr	binstr

		stx	ptr
		sty	ptr+1
		tay
		dey
	loop:
		lda	(ptr),y
		sta	fn_message_cmnd+13,y
		dey
		bpl	loop

		;print	submit_line
		;crlf

		; Sauvegarde la banque active
		; EXEC revient avec la banque 5 active
		lda	VIA2::PRA
		pha

;		clc
		lda	#<fn_message_cmnd
;		adc	save_x
		ldy	#>fn_message_cmnd
;		bcc	go
;		iny
	go:
		ldx	#$00
		.byte	$00, XEXEC

;		jsr	PrintRegs

		; Le code de retour du kernel est dans:
		; Kernel VERSION_2022_2 ($00) -> Acc (pas de code retour de la commande)
		; Kernel VERSION_2022_3 ($00) -> Acc (pas de code retour de la commande)
		; Kernel VERSION_2022_4 ($01) -> Y (code retour de  la commande dans A)

		; Restaure la banque
		pla
		sta	VIA2::PRA

		;cmp	#EOK
		cpy	#EOK
		bne	error

		; Code erreur de la commande dans ERRORLEVEL
;		sta	errorlevel
;		lda	#$00
;		sta	errorlevel+1


		;jsr	submit_reopen

		clc
		rts

	error:
		; Restaure la banque
;		pla
;		sta	VIA2::PRA
;		print	unknown_msg
;		print	submit_line
;		crlf

		;jsr	submit_reopen

;		ldx	save_x
		; Le code de retour du kernel est dans:
		; Kernel VERSION_2022_2 ($00) -> Acc (pas de code retour de la commande)
		; Kernel VERSION_2022_3 ($00)
		; Kernel VERSION_2022_4 ($01) -> Y (code retour de  la commande dans A)
		; lda	#ENOENT
		tya

		sec
		rts

;	unknown_msg:
;		.asciiz "\r\nUnknown command: "

.endproc


