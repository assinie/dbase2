.ifndef USE_LINKEDLIST
	;----------------------------------------------------------------------
	;			includes cc65
	;----------------------------------------------------------------------
	.feature string_escapes

	.include "telestrat.inc"

	;----------------------------------------------------------------------
	;			includes SDK
	;----------------------------------------------------------------------
	.include "SDK.mac"
	.include "types.mac"

	;----------------------------------------------------------------------
	;			include application
	;----------------------------------------------------------------------

	;----------------------------------------------------------------------
	;				imports
	;----------------------------------------------------------------------

	;----------------------------------------------------------------------
	;				exports
	;----------------------------------------------------------------------
	.export var_list
	.export var_search
	.export var_new
	.export var_delete
	.export var_getvalue
	.export var_set_callback

	.exportzp object
	.export entlen
	.export tabase
	.export keylen
	.export keydup

	;----------------------------------------------------------------------
	;			Defines / Constantes
	;----------------------------------------------------------------------

	;----------------------------------------------------------------------
	;				Page Zéro
	;----------------------------------------------------------------------
	.pushseg
		.segment "ZEROPAGE"
			; Gestion de la liste et du dictionnaire
			unsigned short object
			unsigned short pointr
			unsigned short old
	.popseg

	;----------------------------------------------------------------------
	;				Variables
	;----------------------------------------------------------------------
	.pushseg
		.segment "DATA"
			; Gestion de la liste et du dictionnaire
			unsigned short tabase		; Address of base list
			unsigned char entlen		; Total element length
			unsigned char keylen		; key length

			unsigned char keydup		; flag duplicate keys
	.popseg

	;----------------------------------------------------------------------
	;                       Segments vides
	;----------------------------------------------------------------------
	.segment "STARTUP"
	.segment "INIT"
	.segment "ONCE"

	;----------------------------------------------------------------------
	;			Programme principal
	;----------------------------------------------------------------------
	.segment "CODE"

	;----------------------------------------------------------------------
	;
	; Entrée:
	;	object: pointeur vers la variable
	;
	; Sortie:
	;	A,Y: modifiés
	;	X: inchangé
	;	Z: 1->Ok, 0->Erreur
	;
	; Variables:
	;	Modifiées:
	;		-
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc var_new
			jsr	var_search
			bne	store

			lda	keydup
			beq	duplicate

		store:
			ldy	entlen
			dey

		loop:
			lda	(object),y
			sta	(pointr),y
			dey
			bpl	loop

			iny			; Z set if done
			rts

		duplicate:
			lda	#$ff
			rts
	.endproc

	;----------------------------------------------------------------------
	;
	; Entrée:
	;	object: pointeur vers la variable
	;
	; Sortie:
	;	A,Y: modifiés
	;	X: inchangé
	;	Z: 1->found, 0->not found
	;
	; Variables:
	;	Modifiées:
	;		-
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc var_search
			lda	tabase
			sta	pointr
			lda	tabase+1
			sta	pointr+1

		compare:
			ldy	#$00
			lda	(pointr),y
			beq	not_found

			ldy	keylen
		loop:
			dey
			bmi	found
			lda	(pointr),y
			cmp	(object),y
			beq	loop

			clc
			lda	entlen
			adc	pointr
			sta	pointr

			bcc	compare
			inc	pointr+1
			bne	compare

		not_found:
			; Compatibilité avec linked-list
			lda	#$ff
			clv
			rts

		found:
			; Force V=0 (peut être mis à 1 par adc)
			clv
			iny
			rts
	.endproc

	;----------------------------------------------------------------------
	;
	; Entrée:
	;	object: pointeur vers la variable
	;
	; Sortie:
	;	A,Y: modifiés
	;	X: inchangé
	;	Z: 1->Ok , 0->erreur
	;
	; Variables:
	;	Modifiées:
	;		-
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc var_delete
			jsr	var_search
			bne	outs

			; Marque l'entrée comme libre
		next:
			ldy	#$00
			tya
			sta	(pointr),y

			lda	pointr
			sta	old
			lda	pointr+1
			sta	old+1

			clc
			lda	entlen
			adc	pointr
			sta	pointr
			bcc	move
			inc	pointr+1

			; Déplace l'élément suivant vers le bas de la table
		move:
			; Fin de la table?
			;ldy	#$00
			lda	(pointr),y
			beq	outs

			; ldy	#$00
	loop:
			lda	(pointr),y
			sta	(old),y
			iny
			cpy	entlen
			bne	loop

			beq	next

		outs:
			; Force V=0 (peut être mis à 1 par adc)
			clv
			rts
	.endproc

	;----------------------------------------------------------------------
	;
	; Entrée:
	;	object: pointeur vers la variable
	;
	; Sortie:
	;	A,Y: modifiés
	;	X: inchangé
	;	Z: 0->Erreur, 1->Ok
	;
	; Variables:
	;	Modifiées:
	;		-
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc var_list
			lda	tabase
			sta	pointr
			lda	tabase+1
			sta	pointr+1

		loop:
			ldy	#$00
			lda	(pointr),y
			beq	end

			lda	pointr
			sta	object
			lda	pointr+1
			sta	object+1

		callback:
			jsr	end

			clc
			lda	pointr
			adc	entlen
			sta	pointr
			bcc	loop
			inc	pointr+1
			bne	loop

		end:
			; Force V=0 (peut être mis à 1 par adc)
			clv
			rts
	.endproc

	;----------------------------------------------------------------------
	; /!\ A exécuter uniquement après un search
	;
	; Entrée:
	;	object: pointeur destination
	;	pointr: pointeur vers la variable
	;
	; Sortie:
	;	A,Y: modifiés
	;	X: inchangé
	;	Z: 0->Erreur, 1->Ok
	;
	; Variables:
	;	Modifiées:
	;		-
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc var_getvalue
			ldy	#$00
		loop:
			lda	(pointr),y
			sta	(object),y
			iny
			cpy	entlen
			bne	loop

			rts
	.endproc

	;----------------------------------------------------------------------
	;
	; Entrée:
	;	AY: adresse de la routine d'affichage d'une entrée (callback)
	;
	; Sortie:
	;	A,X,Y: inchangés
	;
	; Variables:
	;	Modifiées:
	;		callback_addr
	;
	;	Utilisées:
	;		-
	; Sous-routines:
	;	-
	;----------------------------------------------------------------------
	.proc var_set_callback
			sta	var_list::callback+1
			sty	var_list::callback+2
			rts
	.endproc
.endif

