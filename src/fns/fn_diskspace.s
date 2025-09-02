
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

.import fns_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_diskspace

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
.proc fn_diskspace
		sty	fns_save_y

		; Total - Espace utilisé
		lda	#CH376_DISK_QUERY
		sta	CH376_COMMAND

		jsr	WaitResponse
		beq	error85

		; Nombre d'octets à lire (9 normalement)
		lda	#CH376_RD_USB_DATA0
		sta	CH376_COMMAND

		lda	CH376_DATA
		cmp	#$09
		bne	error85

		; Les 4 premiers octets sont la capacité totale
		; Les 4 suivants l'espace libre
		; Le dernier le type de FAT?

		; On saute les 4 premiers
		ldx	#$04
	loop:
		lda	CH376_DATA
		dex
		bne	loop

		; On conserve les 4 suivants
		; X = -4
		ldx	#$100-4
	loop1:
		; pfac est en page 0 donc pfac+100 = pfac
		lda	CH376_DATA
		sta	pfac+4,x
		inx
		bne	loop1

		; On récupère le dernier octet
		lda	CH376_DATA

		; La valeur est en blocs de 512 octets
		; On converti en blocs de 1K
		lsr	pfac+3
		ror	pfac+2
		ror	pfac+1
		ror	pfac

		; Valeur numérique
		lda	#'N'
		sta	param_type

		ldy	fns_save_y
		clc
		rts

	error85:
		; 85 Error:
		sec
		ldy	fns_save_y
		rts

	.proc WaitResponse
			ldy	#$ff

		loop1:
			ldx	#$ff

		loop2:
			lda	CH376_COMMAND
			bmi	next

			lda	#CH376_GET_STATUS
			sta	CH376_COMMAND
			rts
		next:
			dex
			bne	loop2
			dey
			bne	loop1

			rts
	.endproc
.endproc

