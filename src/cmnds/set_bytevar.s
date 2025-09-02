
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
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp pfac
.import ident
.import param_type
.import cmnd_store

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export set_bytevar

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
;	A: code erreur
;	X,Y: adresse nom de la variable
;
; Sortie:
;	cf cmnd_store
;
; Variables:
;	Modifiées:
;		pfac
;		ident
;		param_type
;	Utilisées:
;		-
; Sous-routines:
;	cmnd_store
;----------------------------------------------------------------------
.proc set_bytevar
		; Adresse du nom de la variable
		stx	varname+1
		sty	varname+2

		; Place le code erreur dans pfac (< 256)
		sta	pfac
		lda	#$00
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3

		ldx	#$ff
	loop1:
		inx
	varname:
		lda	$ffff,x
		sta	ident,x
		bne	loop1

	loop2:
		inx
		cpx	#IDENT_LEN
		bcs	end
		sta	ident,x
		bcc	loop2

	end:
		; Variable de type numérique
		lda	#'N'
		sta	param_type

		; Mise à jour de la variable
		jmp	cmnd_store
.endproc

