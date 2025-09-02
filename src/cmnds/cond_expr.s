
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
.include "case.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From lex
.import lex_prev_y

; From
.import comp_oper
.import param_type
.import string
.importzp pfac
.import bcd_value
.import logic_value

.import param1_type
.import param1
.importzp pfac1

.import input_mode

;.import save_y
.import clear_entry

; From scan.s
.import push_if
.import pop_else

; Utile uniquement pour la vérification de syntaxe compatible submit
.importzp line_ptr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cond_expr

; Pour fn_max, fn_min
.export numcmp

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
len1 := save_a

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

	.segment "DATA"
		unsigned char save_a
		unsigned char len2
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
;	C: 1 -> erreur
;	V: 1 -> test vrai, il peut y avoir une autre instrution à la suite
;	   (compatibilité submit)
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc cond_expr
;		lda	input_mode
;		beq	error95

		; Pour compatibilité submit, il faut vérifier ici qu'il y a
		; quelque chose après la condition sinon si la condition est
		; fausse la syntaxe complète de la commande ne sera pas vérifiée
		; if <condiftion> <instruction>
		;
		; Supprimer cette vérification si la syntaxe est
		;	if <condition>
		;		<bloc_instruction>
		;	endif
		; [
		; lda	(line_ptr),y
		; beq	error10
		; ]

		;ldx	comp_oper

		; Si la syntaxe est
		;	if <condition>
		;		<bloc_instruction>
		;	endif
		; [
;		jsr	push_if
;		bcs	error43
		; ]

		; Paramètres de même type?
		lda	param1_type
		and	#$7f
		sta	save_a
		lda	param_type
		and	#$7f
		cmp	save_a
		;beq	end
		bne	error9

		cmp	#'N'
		bne	suiteD

		jsr	numcmp
		bvc	test

	suiteD:
		cmp	#'D'
		bne	suiteC

		jsr	datecmp
		bvc	test

	suiteC:
		cmp	#'C'
		bne	suiteL

		jsr	strcmp
		bvc	test


	suiteL:
		; cmp	#'L'
		; bne	error

		; Si pas d'opérateur de comparaison -> fin
		lda	comp_oper
		bpl	testL

		lda	logic_value
		clc
		rts

	testL:
		jsr	logcmp

	test:
		jsr	compare
		sta	logic_value

		; [ syntaxe submit
;		beq	end
;		; Test vrai -> V=1 (pour yacc EOI)
;		bit	sev
;
;	end:
;		clc
;	sev:
;		rts
		; ]

		; [ syntaxe dBase
;		bne	true
;
;	false:
;		jmp	pop_else
;
;	true:
	end:
		clc
		rts
		; ]

;	error95:
;		; 95 Valid only in programs.
;		lda	#95
;		ldy	#$00
;		sec
;		rts

;	error43:
;		; 43 Insufficient memory.
;		lda	#43
;		; sec
;		rts

;	error10:
;		; 10 Syntax error.
;		lda	#10
;		sec
;		rts

	error9:
		; 9 Data type mismatch.
		; Replace Y = offset second membre de la comparaison
		; (en fait le dernier terme traité ce qui peut être un paramètre
		; d'une fonction du second membre)
		; TODO: Il faudrait que get_expr_logic conserve l'offset réel du second
		; membre de la comparaison dans une variable
		ldy	lex_prev_y
		lda	#9

		sec
		rts

.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	-
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc logcmp
		lda	param1
		cmp	logic_value
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	-
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc numcmp
.ifdef UNSIGNED_CMP
		; Comparaison non signée
		lda	pfac1
		cmp	pfac
		bne	end

		lda	pfac1+1
		cmp	pfac+1
		bne	end

		lda	pfac1+2
		cmp	pfac+2
		bne	end

		lda	pfac1+3
		cmp	pfac+3

	end:
		rts

.else
		lda	pfac1
		cmp	pfac
		beq	equal

		lda	pfac1+1
		sbc	pfac+1

	b2:
		lda	pfac1+2
		sbc	pfac+2

	b3:
		lda	pfac1+3
		sbc	pfac+3

	neq:
		; [ Positionne C comme pour une comparaison non signée
		bvs	ovflow
		eor	#$80

	ovflow:
		asl
		ora	#$01
		rts
		; ]
		; [ Sinon (dans ce cas il faut utiliser bmi / bpl à la place de bcc / bcs)
;		bvc	end
;		eor	#$80
;	end:
;		rts
		; ]
	equal:
		lda	pfac1+1
		sbc	pfac+1
		bne	b2

		lda	pfac1+2
		sbc	pfac+2
		bne	b3

		lda	pfac1+3
		sbc	pfac+3
		bne	neq
		rts
.endif

.if 0
		; Comparaison signée
		sec
		lda	pfac1
		sbc	pfac

		lda	pfac1+1
		sbc	pfac+1

		lda	pfac1+2
		sbc	pfac+2

		lda	pfac1+3
		sbc	pfac+3
		; Pour que C indique le même résultat que dans le cas d'une
		; comparaison non signée
		bvs	end
		eor	#$80

	end:
		asl
		rts
.endif

.if 0
		; Comparaison non signée
		ldx	#$04
	loop:
		lda	pfac1-1,x
		cmp	pfac-1,x
		bne	end
		dex
		bne	loop

	end:
		rts

		; Comparaison signée
		sec
		lda	pfac1+3			; compare high bytes
		sbc	pfac3
		bvc	label1			; the equality comparison is in the Z flag here

		eor	#$80			; the Z flag is affected here

	label1
		bmi	label4			; if NUM1H < NUM2H then NUM1 < NUM2
		bvc	label2			; the Z flag was affected only if V is 1

		eor	#$80			; restore the Z flag to the value it had after SBC NUM2H

	label2
		bne	label3			; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)

		lda	pfac1+2			; compare low bytes
		sbc	pfac+2
		bcc	label4			; if NUM1L < NUM2L then NUM1 < NUM2

	label3

	label4
.endif
.if 0
		; Comparaison signée 16 bits
		lda	pfac1			; Compare low bytes
		cmp	pfac
		beq	equal			; Branch if they are eqaul

		; Low bytes are not equal - compare high bytes
		lda	pfac1+1
		sbc	pfac+1			; Compare high bytes
		ora	#$01			; Make Z=0 since low bytes are not equal
		bvs	ovflow			; Must handle overflow for signed arithmetic
		rts

	equal:
		lda	pfac1+1
		sbc	pfac+1
		bvs	ovflow
		rts

		; Overflow with signed arithmetic so complement the negative flag
		; do not change the carry flag and make the zero flag equal 0.
		; Complement negative flag by exclusive-oring $80 and accumulator.
	ovflow:
		eor	#$80			; Complement negative flag
		ora	#$01			; If overflow then the words are not equal Z=0
						; Carry unchanged
		rts
.endif

.endproc

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
.proc datecmp
		; bcd: 20 23 01 07

		; Comparaison non signée
		lda	param1
		cmp	bcd_value
		bne	end

		lda	param1+1
		cmp	bcd_value+1
		bne	end

		lda	param1+2
		cmp	bcd_value+2
		bne	end

		lda	param1+3
		cmp	bcd_value+3

	end:
		rts

;		clc
;		rts
.endproc

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
.proc strcmp
		; Calcule la longueur de la seconde chaîne
		ldx	#$ff
	loop2:
		inx
		lda	string,x
		bne	loop2

		stx	len2

		; Calcule la longueur de la première chaîne
		ldx	#$ff
	loop1:
		inx
		lda	param1,x
		bne	loop1

		stx	save_a

		; Compare les longueurs
		cpx	len2
		bcc	cmpstr
		; La seconde est plus courte ou égale, on utilise sa taille pour la comparaison
		ldx	len2

	cmpstr:
		cpx	#$00
		beq	lencmp

		ldy	#$00
	loop:
		lda	param1,y
		cmp	string,y
		bne	end

		iny
		dex
		bne	loop

	lencmp:
		lda	save_a
		cmp	len2

	end:
		rts
.endproc

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
.proc compare
		php
		lda	comp_oper
		plp

		;C=0 -> LT
		;C=1 -> GE
		;Z=0 -> NE
		;Z=1 -> EQ

		bcc	lt
		beq	eq

		; Ici GT
	gt:
		and	#OP_GT
		bne	true
		beq	false

	eq:
		and	#OP_EQ
		bne	true
		beq	false

	lt:
		and	#OP_LT
		bne	true
		beq	false

	true:
		lda	#$ff
		;sta	logic_value
		rts

	false:
		lda	#$00
		;sta	logic_value
		rts
.endproc

