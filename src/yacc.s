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
;.include "include/inifile.inc"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp line_ptr

.import lex_tbl
.import cmnd_addr

.import find_cmnd

.import skip_spaces
.import yacc_tbl

.import affectation

;.import PrintRegs

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
;.export yacc
.export interpret
.export error_code

.exportzp yacc_ptr

.export token_start

; [ Compatibilité submit (exécution d'une commande sans "!" ni "run"
.importzp pfac
.import cmnd_run
; ]

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
.include "include/dbase.inc"

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short yacc_ptr
;		unsigned short work_ptr

	.segment "DATA"
		unsigned char error_code

		; [*] pour debug
		unsigned char cmnd_number
;		unsigned char rule_number
		unsigned char rule_step
		unsigned char lex_number

		unsigned char token_start

		unsigned char start_y
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
; Interprète une règle syntaxique
;
; Entrée:
;	Y: offset dans la ligne
;
; Sortie:
;	C: 0->Ok, 1->Erreur
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc interpret
		lda	line_ptr
		ldx	line_ptr+1
		jsr	find_cmnd
		bcs	not_found

		; [*] Sauvegarde le n° de la régle à activer (n° de la commande)
		stx	cmnd_number

		; Sauvegarde l'offset dans la ligne de commande
		sty	start_y

		; Adresse de la règle
		txa
		asl
		tay
		lda	yacc_tbl+1,y
		tax
		lda	yacc_tbl,y

		; Restaure Y
		ldy	start_y

		; Exécution de la règle
		jsr	yacc
		bcs	yacc_end
		bvc	yacc_end

		; On a exécuté une instruction mais on peut en avoir une autre
		; après (cas de if xxxx cmnd pour compatibilité avec submit)
		ldy	save_y
		jmp	interpret

	yacc_end:
		clv
		rts

	not_found:
		lda	line_ptr
		ldx	line_ptr+1
		clc
		jsr	affectation

		; Sauvegarde le code erreur dans X
		tax

		; Si on veut tenter l'exécution d'une commande externe à partir
		; de interpret
		; [
		bcc	eol
		; Erreur de syntaxe ou pas une affectation?
		bvc	end
		; Ici V=1 -> ce n'était pas une affectation
		; jsr	PrintRegs
	error16:
	.ifndef SUBMIT
		; 16 *** Unrecognized command verb.
		clv
		ldx	#16
		bne	end
	.else
		lda	line_ptr
		sta	pfac
		lda	line_ptr+1
		sta	pfac+1
		jmp	cmnd_run
	.endif
		; jmp	end
		; sinon tester V dans la routine appelante
		; ]
	eol:
		; Vérifie qu'on est bien en fin de ligne après une affectation
		lda	(line_ptr),y
		beq	end

	error10:
		ldx	#10
		sec

	end:
		; Remet le code erreur dans A
		txa
		rts
.endproc

;----------------------------------------------------------------------
; Interprète une règle syntaxique
;
; Entrée:
;	AX: adresse de la règle
;	Y: offset dans la ligne
;	line_ptr: adresse de la ligne
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
.proc yacc
		sty	save_y
		sta	yacc_ptr
		stx	yacc_ptr+1

		; [*] N° du pas dans la règle
		lda	#$ff
		sta	rule_step

	loop:
		; [*] incrémente le numéro de pas
		inc	rule_step

;		inc	ptr
;		bne	skip
;		inc	ptr+1

	skip:
		; Saute les ' '
		lda	line_ptr
		ldx	line_ptr+1
		ldy	save_y
		jsr	skip_spaces
		sty	save_y

		; Caractère attendu?
		ldy	#$00
		lda	(yacc_ptr),y
		; [*] Sauvegarde le n° du lexème
		sta	lex_number

		; Expression attendue?
		bmi	expect_char

		; Non, on récupère l'adresse du lexème à vérifier
		asl
		tax
		lda	lex_tbl,x
		sta	instr+1
		lda	lex_tbl+1,x
		sta	instr+2

		; Avance au pas suivant
	next:
		inc	yacc_ptr
		bne	_exec
		inc	yacc_ptr+1

		; Vérification de l'expression
	_exec:
		lda	line_ptr
		ldx	line_ptr+1
		ldy	save_y
		sty	token_start
		clc
	instr:
		; AX: pointeur vers la ligne source
		; Y : offset  dans la ligne
		; C : 0
		jsr	$ffff
		sty	save_y
		; Si pas d'erreur -> boucle
		bcc	loop

		; Erreur
		rts

		; Avance au pas suivant
	expect_char:
		inc	yacc_ptr
		bne	@skip
		inc	yacc_ptr+1

	@skip:
		; Fin de ligne attendue? ($ff = EOL)
		ldy	save_y
		cmp	#$ff
		beq	end

		cmp	#$fe
		beq	eoi

		; Non, on attend un caractère particuler
		; Caractère attendu trouvé?
		and	#$7f
		cmp	(line_ptr),y
		bne	error10

		; Oui, on boucle pour l'étape suivante
		iny
		sty	save_y
		clc
		bne	loop

	error10:
		; 10 Syntax error.
		lda	#10
		sec
		rts

	end:
		; Fin de ligne atteinte?
		lda	(line_ptr),y
		bne	error10

	eoi:
		; Faut-t-il exécuter une fonction à la fin de la ligne?
		ldy	#$00
		lda	(yacc_ptr),y
		cmp	#$ff
		beq	exit

		; Oui, on l'exécute et fin
		asl
		tax
		lda	cmnd_addr,x
		sta	cmnd+1
		lda	cmnd_addr+1,x
		sta	cmnd+2

		lda	cmnd_number
		ldy	save_y
		ldx	token_start
	cmnd:
		; A = n° de la commande
		; Y = offset vers le caractère suivant dans la ligne
		; X = offset dernier token lu
		jmp	$ffff

	exit:
		; Pas de commande, on sort sans erreur
		clc
		rts
.endproc


