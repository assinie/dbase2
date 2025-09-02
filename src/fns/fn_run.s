
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
.import string

.import cmnd_run

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_run

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
		unsigned char save_scr[5]

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
;	pfac: adresse de la chaine contenant la commande
;
; Sortie:
;	A: code retour de la commande
;	X: modifié
;	Y: modifié
;	C: 0 -> Ok, 1-> commande inconnue
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_run
		; Intialise string
		ldx	#128
		lda	#$00
	loop:
		sta	string,x
		dex
		bpl	loop

		; /!\ Bricolage pour récupérer la sortie écran d'une commande
		; [
		; Sauvegarde les variables écran
		lda	ADSCRL
		sta	save_scr
		lda	ADSCRH
		sta	save_scr+1
		lda	SCRX
		sta	save_scr+2
		lda	SCRY
		sta	save_scr+3
		lda	CURSCR
		sta	save_scr+4

		lda	#$00
		sta	SCRX
		sta	SCRY
		sta	SCRNB
		lda	#<string
		sta	ADSCRL
		lda	#>string
		sta	ADSCRH
		; ]

		; Exécute la commande
		cursor	off
		jsr	cmnd_run
		php
		cursor	on

		; /!\ Fin du bricolage
		; [
		; Restaure les variables écran
		ldx	save_scr
		stx	ADSCRL
		ldx	save_scr+1
		stx	ADSCRH
		ldx	save_scr+2
		stx	SCRX
		ldx	save_scr+3
		stx	SCRY
		ldx	save_scr+4
		stx	CURSCR
		; ]

		plp
		rts
.endproc

