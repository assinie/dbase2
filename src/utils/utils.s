;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "errno.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import submit_line

.import cmnd_table

.import entry

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export find_cmnd
.export _find_cmnd
.export clear_entry
;.export xbindx

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		const_10_decimal_low:
			.lobytes	10, 100, 1000, 10000

		const_10_decimal_high:
			.hibytes	10, 100, 1000, 10000
.popseg

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short ptr
.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
;		unsigned char CurCharPos
		unsigned char save_x
		unsigned char instnum

;		unsigned char save_a

		unsigned char save_y
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"


;----------------------------------------------------------------------
;
; Entrée:
;	AX: adresse de la ligne
;	Y: offset dans la ligne
;
; Sortie:
;	Cf. find_cmnd
;
; Variables:
;	Modifiées:
;		-
;
;	Utilisées:
;		-
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc find_cmnd
		sta	ptr
		stx	ptr+1
		sty	save_y

		; Copie de _argv dans submit_line
		ldy	#$ff
	loop:
		iny
		lda	(ptr),y
		sta	submit_line,y
		bne	loop

		ldx	save_y
		lda	#<cmnd_table
		ldy	#>cmnd_table
		jsr	_find_cmnd
		bcs	error

		; Sortie:
		; A = caractère suivant la commande
		; Y = offset du caractère après la commande
		; X = n° de la commande
		stx	save_y
		ldy	save_y
		tax
		lda	submit_line,y
		rts

	error:
		; En cas d'erreur de find_cmd X est inchangé
		; Il est donc égale à save_y
		; (on évite txa / tay qui écrase A)
		ldy	save_y
		lda	submit_line,y
		sec
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	AY: Adresse de la table des commandes
;	X: Offset de la commande dans submit_line
;
; Sortie:
;	Commande trouvée:
;		C: 0
;		A: n° de la commande
;		X: index vers la caractère suivant la commande
;
;	Commande inconnue:
;		C: 1
;		A: modifié
;		X: inchangé
;	Y: modifié
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc _find_cmnd
		sta	ptr
		sty	ptr+1

		.if ::LOOKUP_TABLE_PAGE
				; [ Si les tables sont limitées à 256 caractères maxi
				; ]
		.else
				; [ sinon
				; Modifier les appels à _find_cmnd pour passer en paramètre
				; l'adresse de la table -1
				lda	ptr
				bne	@dec_lsb
				dec	ptr+1
			@dec_lsb:
				dec	ptr
			@skip:
				; ]
		.endif

		; X: position du premier caractère de la commande
		; à trouver
		lda	submit_line,x
		beq	notfound

	lookup:
		dex
		stx	save_x

		ldy	#$00
		sty	instnum

		.if ::LOOKUP_TABLE_PAGE
				; [ Si les tables sont limitées à 256 caractères maxi
				dey
				; ]
		.else
				; [ sinon
				; ]
		.endif

	loop:

		.if ::LOOKUP_TABLE_PAGE
				; [ Si les tables sont limitées à 256 caractères maxy
				iny
				;]
		.else
				; [ sinon
				inc	ptr
				bne	@skip
				inc	ptr+1
			@skip:
				; ]
		.endif

		inx
		lda	submit_line,x
		; Si on a deux instructions dont l'une est inclue dans l'autre,
		; il faut placer la plus courte en premier dans la table
		; Ex.: DISP et DISPLAY
		; [
;		beq	not_found
;		cmp	#' '
;		bne	first_char
;
;	not_found:
;		sec
;		lda	#ENOENT
;		rts
		; ]
		; Sinon, on active uniquement cette ligne à la place du bloc
		; précédent.
		beq	next

		cmp	#'a'
		bcc	compare
		cmp	#'z'+1
		bcs	compare
		sbc	#'a'-'A'-1

	compare:
		cmp	(ptr),y
		beq	loop

		lda	(ptr),y
		beq	notfound

		and	#$7f
		; si pas de conversion minuscules / majuscule
		; cmp	submit_line,x
		; beq	found
		; sinon
	case_insensitive:
		sec
		sbc	submit_line,x
		beq	found
		cmp	#$100-$20
		beq	found

	next:
		ldx	save_x
		inc	instnum

	skip_string:
		lda	(ptr),y
		bmi	loop

		.if ::LOOKUP_TABLE_PAGE
				; [ Si les tables sont limitées à 256 caractères maxy
				iny
				; ]
		.else
				; [ sinon
				inc	ptr
				bne	@skip
				inc	ptr+1
			@skip:
				; ]
		.endif

		bne	skip_string

	notfound:
		sec
		lda	#ENOENT
		rts

	found:
		; Pointe vers le caractère suivant la commande
		inx

		; Ajout test pour les fonctions ex.: CHR(
		; [
		lda	submit_line-1,x
		cmp	#'('
		beq	ok
		; ]

		; Vérifie que le prochain caractère du buffer est bien un espace
		; ou la fin de ligne.
		; Dans le cas contraire on passe à la commande suivante.
		; Ex: buffer: cata => commande trouvée = cat => pas bon
		lda	submit_line,x
		beq	ok
		cmp	#' '
		bne	next

	ok:
		lda	instnum
		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	A: 0
;	Y: $ff
;	X: inchangé
;
; Variables:
;	Modifiées:
;		entry
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc clear_entry
		ldy	#ENTRY_LEN-1
		lda	#$00
	loop:
		sta	entry,y
		dey
		bpl	loop

		rts
.endproc

;----------------------------------------------------------------------
; Routine du kernel modifiée pour gérer la suppression de la justification
; à droite.
;
; Entrée:
;	AY: Valeur (A=LSB)
;	X: Puissance de 10
;	TR5-TR6: Adresse du buffer
;
; Sortie:
;	A: Dernier chiffre (ASCII)
;	X: $ff
; 	Y: Offset du dernier caractère
;
; Variables:
;       Modifiées:
;               TR0
;		TR1
;		TR2
;		TR3
;		TR4: nombre de caractères du nombre
;
;       Utilisées:
;		DEFAFF
;               TR5-TR6
;		const_10_decimal_low
;		const_10_decimal_high
;
; Sous-routines:
;       -
;----------------------------------------------------------------------
.if 0
.proc xbindx
		sta	TR1
		sty	TR2

		lda	#$00 ; 65c02
		sta	TR3
		sta	TR4
	L5:
		lda	#$FF
		sta	TR0

	L4:
		inc	TR0
		sec
		lda	TR1
		tay
		sbc	const_10_decimal_low,X
		sta	TR1
		lda	TR2
		pha
		sbc	const_10_decimal_high,X ;
		sta	TR2
		pla
		bcs	L4
		sty	TR1
		sta	TR2
		lda	TR0
		beq	L2
		sta	TR3
		bne	L3+1

	L2:
		ldy	TR3
		bne	L3+1
		lda	DEFAFF
		; Modification
		; [
		beq	next
		; ]

	L3:
		.byt	$2C
		ora	#$30

		jsr	L1

	next:
		dex
		bpl	L5
		lda	TR1
		ora	#$30
	L1:
		ldy	TR4
		sta	(TR5),Y
		inc	TR4

		rts
.endproc
.endif
