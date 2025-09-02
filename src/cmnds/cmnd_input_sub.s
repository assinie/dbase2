
;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import readline

.importzp line_ptr
.importzp pfac

.import string
.import ident
.import param_type

.import cmnd_store

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_input_sub

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		; unsigned short ptr

	.segment "DATA"
		; unsigned char ident_save[IDENT_LEN+1]
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Basé sur cmnd_input
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc cmnd_input_sub
		lda	pfac+1
		ora	pfac+2
		ora	pfac+3
		bne	error11

		ldx	pfac
		beq	len_max

		inx
		cpx	#VARS_DATALEN
		bcc	disp_string

	error11:
		; 11 Invalid function argument.
		lda	#11
		sec
		rts

	len_max:
		ldx	#VARS_DATALEN

	disp_string:
		stx	pfac
		lda	string
		beq	accept

		print	string

	accept:
		input	, pfac, line_ptr

		crlf

		; Copie de la chaine
		ldy	#$ff
	loop1:
		iny
		lda	(line_ptr),y
		sta	string,y
		bne	loop1

		lda	#'C'
		sta	param_type
		jmp	cmnd_store
.endproc

