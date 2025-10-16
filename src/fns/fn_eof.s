
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

; From fn_isopen.s
;.import fn_isopen

; From fns.lib
.import fn_eof

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_dbf_eof

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
; dBase III: si pas de base ouverte: eof = .F.
; bof() == .T. si on est avant le premier enregistrement logique
;----------------------------------------------------------------------
.proc fn_dbf_eof
	;	jsr	fn_isopen
	;	bcc	eof

	;	; Pas de base ouverte
	;	lda	#$00
	;	beq	end

	eof:
		jsr	fn_eof

	end:
		sta	logic_value

		; Résultat de type L
		lda	#'L'
		sta	param_type

		clc
		rts
.endproc

