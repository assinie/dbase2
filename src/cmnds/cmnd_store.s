
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
.import param_type

.import clear_entry
.import entry

.import var_new
.import var_search
.import var_getvalue
.importzp object

.import ident
.import string
.import value
.import bcd_value
.import logic_value

.import vars_index
.import vars_data_index

; From strbin
.importzp pfac

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_store

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
		unsigned short ptr

	.segment "DATA"
		unsigned char save_y
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
; dBase: affectation d'une valeur à un champ de la base ne modifie pas
;        la valeur de ce champ et ne retourne pas d'erreur. Il faut
;        utiliser la commande REPLACE
;----------------------------------------------------------------------
.proc cmnd_store
		sty	save_y

		; var_type: type de la valeur
		lda	param_type
		bpl	int_string

		; Il s'agit d'une variable
		and	#$7f
		sta	param_type
		bne	store

	int_string:
		jsr	clear_entry

	store:
		lda	#<entry
		sta	object
		lda	#>entry
		sta	object+1

		; Met à jour le nom de la variable
		ldx	#IDENT_LEN
	loop:
		lda	ident,x
		sta	entry+st_entry::name,x
		dex
		bpl	loop

		; Si vérification du type
		; [
;		jsr	var_search
;		bne	not_found
;		lda	entry+st_entry::type
;		cmp	var_type
;		bne	type_mismatch
;	not_found:
		; ]
		; Sinon
		; [
		jsr	var_search
		bne	create
		jsr	var_getvalue
		beq	found

	create:
		lda	vars_index
		cmp	#VARS_MAX
		bcs	error21

		; On met à jour data_ptr
		lda	vars_data_index
		sta	entry+st_entry::data_ptr
		lda	vars_data_index+1
		sta	entry+st_entry::data_ptr+1

		; Mise à jour des pointeurs
		inc	vars_index

		clc
		lda	#VARS_DATALEN
		adc	vars_data_index
		sta	vars_data_index
		lda	#$00
		adc	vars_data_index+1
		sta	vars_data_index+1
		; ]

	found:
		lda	entry+st_entry::data_ptr
		sta	ptr
		lda	entry+st_entry::data_ptr+1
		sta	ptr+1

		lda	param_type
		sta	entry+st_entry::type

		cmp	#'N'
		beq	store_numeric

		cmp	#'L'
		beq	store_logical

		cmp	#'C'
		beq	store_string

		cmp	#'D'
		bne	error10

	store_date:
		; Valeur BCD sur 4 octets
		ldy	#$00
	@loop:
		lda	bcd_value,y
		sta	(ptr),y
		iny
		cpy	#$04
		bne	@loop
		beq	update_var

	store_string:
		; Valeur chaine
		ldy	#$ff
	loop1:
		iny
		lda	string,y
		sta	(ptr),y
		bne	loop1
		beq	update_var

	store_logical:
		ldy	#$00
		lda	logic_value
		sta	(ptr),y
		iny
		bne	update_var

	store_numeric:
;		ldy	#$ff
;	loop2:
;		iny
;		lda	value,y
;		sta	(ptr),y
;		bne	loop2
		ldy	#$ff
	loop2:
		iny
		lda	pfac,y
		sta	(ptr),y
		cpy	#$04
		bne	loop2

	update_var:
		sty	entry+st_entry::len
		jsr	var_new
		ldy	save_y
		clc
		rts


	error10:
		; 10 Syntax error.
		lda	#10
		.byte	$2c

	error21:
		; 21 Out of memory variable memory.
		lda	#21

		ldy	save_y
		sec
		rts


;	type_mismatch:
;		ldy	save_y
;		lda	#$01
;		sec
;		rts
.endproc


