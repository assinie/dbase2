
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
.importzp fns_ptr

.importzp pfac

.import param_type
.import string

.import fns_save_y

.import uname
.import os_default

.import fn_run

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_os

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
; os()
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
.if 1
	.proc fn_os
			sty	fns_save_y
			; lda	#'C'
			; sta	param_type

			lda	#<uname
			sta	pfac
			lda	#>uname
			sta	pfac+1

			; Exécute la commande
			jsr	fn_run
			bcc	end

			; Erreur d'exécution de la commande uname -a
			; On remplace le message d'erreur de cmnd_run
			ldx	#$ff
		loop1:
			inx
			lda	os_default,x
			sta	string,x
			bne	loop1

		end:
			lda	#'C'
			sta	param_type

			ldy	fns_save_y
			clc
			rts
	.endproc
.endif
;----------------------------------------------------------------------
; os()
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
; Version kernel >= 2023.2
;----------------------------------------------------------------------
.if 0
	.proc fn_os
			sty	fns_save_y
			; lda	#'C'
			; sta	param_type

			ldx	#$09
			.byte $00, XVARS

			sta	fns_ptr
			sty	fns_ptr+1

			ldy	#$ff
		loop:
			iny
			lda	(fns_ptr),y
			sta	string,y
			bne	loop

			lda	#'C'
			sta	param_type

			ldy	fns_save_y
			clc
			rts
	.endproc
.endif
