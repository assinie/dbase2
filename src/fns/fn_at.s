
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
.import param1

.import is_pfac_byte

.importzp fns_ptr
.import fns_save_a
.import fns_save_y

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export fn_at

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
; at(<expC>, <expC>)
;
; Entrée:
;	-
; Sortie:
;	- A: modifié
;	- X: modifié
;	- Y: inchangé
;	- C: 0
;
; Variables:
;	Modifiées:
;		- param_type
;		- pfac
;		- fns_ptr
;		- fns_save_a
;		- fns_save_y
;	Utilisées:
;		- param1
;		- string
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc fn_at
		sty	fns_save_y

		lda	#'N'
		sta	param_type

		; Clear pfac
		lda	#$00
		sta	pfac
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3


		; Vérifie que les chaines ne sont pas vides
		lda	param1
		beq	end

		lda	string
		beq	end

		; Calcul longueur string
		ldx	#$ff
	loop:
		inx
		lda	string,x
		bne	loop
		stx	fns_ptr+1

		; Calcul longueur param1 (sous-chaine)
		ldx	#$ff
	loop1:
		inx
		lda	param1,x
		bne	loop1

		; Sous chaine plus grande que la chaine?
		cpx	fns_ptr+1
		beq	ok
		bcs	end

;;		; Ici: A=len(sous-chaine), fns_ptr+1=len(chaine)

	ok:
		stx	fns_ptr
		;lda	#$00
		;sta	index
		;lda	slen
		lda	fns_ptr+1
		sec
		;sbc	sublen
		sbc	fns_ptr
		;sta	count
		;inc	count
		sta	fns_save_a
		inc	fns_save_a

	search:
		;lda	index
		;sta	sidx
		ldx	pfac
		;lda	#$00
		;sta	subidx
		ldy	#$01

	comp:
		;ldy	sidx
		lda	string,x
		;ldy	subidx
		cmp	param1-1,y
		bne	comp2

		;ldy	subidx
		;cpy	sublen
		cpy	fns_ptr
		beq	found

		iny
		;sty	subidx
		;inc	sidx
		inx
		jmp	comp

	comp2:
		;inc	index
		inc	pfac
		;dec	count
		dec	fns_save_a
		bne	search
		;beq	notfound

	notfound:
		; Transformé en 0 par le inc
		lda	#$ff
		sta	pfac

	found:
		; Indique 1 pour le premier caractère (0 si non trouvé)
		;lda	index
		;sta	pfac
		inc	pfac

	end:
		ldy	fns_save_y
		clc
		rts
.endproc

