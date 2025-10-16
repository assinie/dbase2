;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes
.feature loose_char_term

.include "telestrat.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"
.include "case.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; Chaines statiques
.import opt_on_off

; From main
.import submit_line

; From utils
.import _find_cmnd

; From lex
.importzp lex_ptr
.import on_off_flag
.import lex_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export get_on_off

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
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"

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
; "ON | OFF | TO"
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	A: dernier caractère lu ou code erreur
;	Y: offset vers le dernier caractère lu
;	C: 0-> Ok, 1->erreur (option on trouvée)
;	Z: fonction du dernier caractère lu (Z=1 -> EOL)
;
; Variables:
;	Modifiées:
;		lex_save_y
;		on_off_flag: 0->'OFF', 1->'ON', 2->'TO', $ff-> ''
;
;	Utilisées:
;		opt_on_off
;		submit_line
;
; Sous-routines:
;	_find_cmnd
;----------------------------------------------------------------------
.proc get_on_off
	;	sta	lex_ptr
	;	stx	lex_ptr+1

	;	lda	(lex_ptr),y
	;	bne	get_opt

	;	lda	#$ff
	;	sta	on_off_flag
	;	bne	end

	get_opt:
		sty	lex_save_y
		ldx	lex_save_y
		lda	#<opt_on_off
		ldy	#>opt_on_off
		jsr	_find_cmnd
		bcs	error

		; Sortie:
		; A = caractère suivant la commande
		; Y = offset du caractère après la commande
		sta	on_off_flag
		stx	lex_save_y
	end1:
		ldy	lex_save_y
	end:
		lda	submit_line,y
		rts

	;	clc
	;	rts
	;error:
	;	ldy	lex_save_y
	;	; Syntax error.
	;	lda	#10
	;	sec
	;	rts

	error:
		lda	#$ff
		sta	on_off_flag
		clc
		bcc	end1
.endproc

