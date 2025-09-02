
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
.import ident

.importzp object
.import entry

.import clear_entry

.import var_search
.import var_delete

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_release

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
; RELEASE <varmem>
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
.proc cmnd_release
		; Initialise entry
		jsr	clear_entry

		; On suppose que sizeof(ident) = keylen
		ldx	#$ff
	loop:
		inx
		lda	ident,x
		sta	entry,x
		bne	loop

		lda	#<entry
		sta	object
		ldy	#>entry
		sty	object+1

		; Pas d'erreur si la variable n'existe pas
		jsr	var_search
		bne	end

		jsr	var_delete

	end:
		clc
		rts
.endproc


