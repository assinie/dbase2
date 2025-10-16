
;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"
.include "errno.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"
.include "ch376.inc"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp pfac

.import param_type
.import ident
.import value
.import string
.import bcd_value
.import logic_value

.import is_pfac_byte

; From lex
.importzp lex_work_ptr

; From dbf.lib
.import dbf_isopen

; From fns.lib
.import fn_dbf

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_dbf_dbf

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
.proc fn_dbf_dbf
		sty	save_y+1

		; Renvoie une chaine
		lda	#'C'
		sta	param_type
		lda	#$00
		sta	string

		; Base ouverte?
		jsr	dbf_isopen
		bne	end

		; On récupère le nom du fichier
		jsr	fn_dbf

		; Copie dans string
		sta	lex_work_ptr
		sty	lex_work_ptr+1
		ldy	#$ff
	loopC:
		iny
		lda	(lex_work_ptr),y
		sta	string,y
		bne	loopC

	end:
	save_y:
		ldy	#$ff
		clc
		rts
.endproc

