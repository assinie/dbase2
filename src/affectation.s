
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

.importzp fns_ptr
.import fns_save_y
.import fns_ident_dst


.import skip_spaces
;.import get_expr
.import get_term
.import get_ident

.import _find_cmnd

.import cmnd_store

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export affectation

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
;	C: 0-> Ok, 1->erreur
;	V: 1-> pas de signe '=' (pas une affectation)
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
; dBase: affectation d'une valeur à un champ de la base ne modifie pas
;        la valeur de ce champ et ne retourne pas d'erreur. Il faut
;        utiliser la commande REPLACE
;----------------------------------------------------------------------
.proc affectation
		sta	fns_ptr
		stx	fns_ptr+1
		sty	fns_save_y

		; On est arrivé avec C=0 => fin identificateur sur caractère
		; non alphanumérique
		jsr	get_ident
		bcs	error

		; Sauvearde le nom de la variable
		; (get_param écrase ident)
		ldx	#IDENT_LEN
	loop:
		lda	ident,x
		sta	fns_ident_dst,x
		dex
		bpl	loop

		lda	fns_ptr
		ldx	fns_ptr+1
		jsr	skip_spaces

		cmp	#'='
		bne	error_noeq
		iny

		lda	fns_ptr
		ldx	fns_ptr+1
		jsr	skip_spaces
.if 0
		cmp	#'"'
		beq	chaine
		cmp	#'''
		beq	chaine
		cmp	#'9'+1
		bcc	valeur

		; Copier l'identificateur avant l'appel à get_ident
		lda	fns_ptr
		jsr	get_ident

		rts

	chaine:
		; ici C=1 => chaine avec délimiteurs
		lda	fns_ptr
		ldx	fns_ptr+1
		jsr	get_string
		rts

	valeur:
		; ici C=0 => valeur non signée
		cmp	#'0'
		bcc	error

		lda	fns_ptr
		ldx	fns_ptr+1
		jsr	get_int
		rts

	error:
		lda	#01
		ldy	fns_save_y
		sec
		rts
.endif
.ifdef TEST
		lda	fns_ptr
		jsr	get_param
		bcc	store

		; Fonction?
		sty	fns_save_y
		ldx	fns_save_y
		lda	#<fns
		ldy	#>fns
		jsr	_find_cmnd
		; Replace l'offset dans la ligne dans Y
		stx	fns_save_y
		ldy	fns_save_y
		bcc	function

		sec
		rts

	error:
		lda	#01
		ldy	fns_save_y
		sec
		rts

		; Restaure ident
	store:
		ldx	#IDENT_LEN
	loop1:
;		inx
		lda	fns_ident_dst,x
		sta	ident,x
;		bne	loop1
		dex
		bpl	loop1
		jmp	cmnd_store

	function:
		sta	fns_save_a
		lda	fns_ptr
		ldx	fns_ptr+1
		jsr	skip_spaces
		sty	fns_save_y
		lda	fns_ptr
		jsr	get_param
		;bcs	error
		bcc	ok

		; Saute le paramètre [valable uniquement pour TYPE()]
		lda	fns_save_a
		cmp	#TOKEN_TYPE
		bne	error

		lda	fns_ptr
		sta	work_ptr
		lda	fns_ptr+1
		sta	work_ptr+1
		dey
	loop2:
		iny
		lda	(work_ptr),y
		beq	error
		cmp	#')'
		bne	loop2
		; Indique paramètre inconnu
		lda	#'U'
		sta	param_type

	ok:
;		sty	fns_save_y
		lda	fns_ptr
		ldx	fns_ptr+1
		jsr	skip_spaces

		cmp	#')'
		bne	error

		iny
;		sty	fns_save_y
		lda	fns_save_a
		asl
		tax
		lda	fn_addr,x
		sta	_jsr+1
		lda	fn_addr+1,x
		sta	_jsr+2
	_jsr:
		jsr	$ffff
		bcc	store
		bcs	error
.else

		lda	fns_ptr
		; jsr	get_expr
		; Autorise <val> <op> <val>
		jsr	get_term
		bcs	end

		; Restaure ident
		ldx	#IDENT_LEN
	loop1:
		;inx
		lda	fns_ident_dst,x
		sta	ident,x
		;bne	loop1
		dex
		bpl	loop1
		jmp	cmnd_store

	error_noeq:
;		lda	#$02
		; Restaure les registres
		lda	fns_ptr
		ldx	fns_ptr+1
		ldy	fns_save_y

		; Indique pas une affectation
		bit	sev
		sec
		rts

	error:
;		ldy	fns_save_y
;		lda	#01
		sec
	end:
		clv
	sev:
		rts
.endif

.endproc










