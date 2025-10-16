;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes, loose_char_term

.include "telestrat.inc"
.include "errno.inc"

.macpack longbranch
;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "macros/utils.mac"
.include "include/dbase.inc"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From fgets.s
.import fpos_text
.import fpos_prev
.import linenum
.import fgets
.import buffer_reset

; From main.s
.importzp line_ptr
.import submit_line

; From cmnd_procedure
.import forward_label

; From cmnd_label.s (à remplacer par cmnd_procedure)
.import cmnd_label

; From debug.s
.import StopOrCont
.import PrintHexByte

; From utils.s
.import _find_cmnd

; From lex_common.s
.import skip_spaces

; From file.s
.import file_fpos
.import file_empty_stack

; From fseek.s
.import fseek

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export scan

.export push_if
.export pop_else
.export pop_endif
.export flow_loop
.export flow_exit

.export flow_stack

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
typedef .struct if_item
	unsigned short if_line			; 2
	unsigned long if_offset			; 4
	unsigned short else_line		; 2
	unsigned long else_offset		; 4
	unsigned short endif_line		; 2
	unsigned long endif_offset		; 4
	unsigned char token			; 1
	unsigned char dummy			; 1
.endstruct

.define IF_MAX 12

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		scan_tbl:
			string80	"IF"
			string80	"ELSE"
			string80	"ENDIF"
			string80	"WHILE"		; "DO WHILE"
			string80	"WEND"		; "LOOP"
;			string80	"REPEAT"	; "DO"
;			string80	"UNTIL"		; "LOOP WHILE"
			string80	"TEXT"
			string80	"ENDTEXT"
			.byte		$00

		TOKEN_IF = 0
		TOKEN_ELSE = 1
		TOKEN_ENDIF = 2
		TOKEN_WHILE = 3
		TOKEN_WEND2 = 4
		TOKEN_REPEAT = 5
		TOKEN_UNTIL = 6
		TOKEN_TEXT = 7
		TOKEN_ENDTEXT = 8

	.segment "DATA"
		; Table des blocs
		unsigned char if_table[IF_MAX * .sizeof(if_item)]
		unsigned char if_ptr

		; Pile pour les if imbriqués
		unsigned char flow_stack
		unsigned char if_stack[IF_MAX]

		; Pour la vérification de la syntaxe
		unsigned char if_stack_syntax[IF_MAX]

.out .sprintf("if_table size : %d", .sizeof(if_table))
.out .sprintf("if stack depth: %d", IF_MAX)


.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	AY: Adresse du tampon
;	X : Taille du tampon
;
; Sortie:
;	A  : 0 ou code erreur
;	X  : Modifié
;	Y  : 0
;	C=0: Ok
;	C=1: Erreur
;
; Variables:
;       Modifiées:
;               address
;		max_line_size
;       Utilisées:
;               -
; Sous-routines:
;       fgetc
;----------------------------------------------------------------------
.proc scan
		lda	#($100-.sizeof(if_item))
		sta	if_ptr

		lda	#$00
		sta	flow_stack
;		sta	if_flag

		sta	if_stack
		sta	if_stack_syntax

		sta	linenum+1
		sta	linenum

	.if ::VERBOSE_LEVEL > 0
		crlf
	loop:
		cputc	$0d
		jsr	print_linenum
;		cputc	':'
	.else
	loop:
	.endif

		lda     #<submit_line
		ldy     #>submit_line
		sta	line_ptr
		sty	line_ptr+1
		ldx     #LINE_MAX_SIZE

		jsr	fgets
		jcs	end

	.if ::VERBOSE_LEVEL > 0
;		print	submit_line
		jsr	StopOrCont
		jcs	end
	.endif

		ldy	#$00
		lda	line_ptr
		ldx	line_ptr+1
		; /?\ il faudrait déporter le skip_sapces juste avant la recherche
		;     des tokens (':', '#', ';', '*' et PROCEDURE sont supposés
		;     être en début de ligne.
		; [
		jsr	skip_spaces
		; ]
		lda	submit_line,y
		; Ligne vide?
		beq	loop

	.ifdef LABEL_CHR
		; [ Spécifique submit (équivalent de PROCEDURE)
		; Label?
		cmp	#LABEL_CHR
		bne	remark

		jsr	cmnd_label
		bcc	loop
		jmp	error_label
		; ]
	.endif

	remark:
		; Si le premier caractère est un '*' (ou ';') c'est un commentaire
		cmp	#REM_CHR
		beq	loop

	.ifdef SUBMIT
		; [ Compatibilité submit
		cmp	#'#'
		beq	loop
		; ]
	.endif

		; Les instructions peuvent être indentées
		; [
		; jsr	skip_spaces
		; beq	loop
		; ]

		; Case insensitive
		clc
		; Transfère Y dans X
		tya
		tax

                lda     #<scan_tbl
                ldy     #>scan_tbl
		jsr	_find_cmnd
		bcs	loop

		; Ici A: n° du token
		; TODO: ajouter la gestion de PROCEDURE pour dBase
		cmp	#TOKEN_TEXT
		bne	if
		jsr	skip_text
		bcc	loop
		; Fin de fichuer atteinte et pas de ENDTEXT trouvé
		;jcs	end
		jcs	error10

	if:
		; Sauvegarde le token pour plus tard
		tax

		cmp	#TOKEN_IF
		beq	if1

		cmp	#TOKEN_WHILE
		bne	else

	if1:
		inc	flow_stack
		ldy	flow_stack
		; Trop de blocs imbriqués?
		cpy	#IF_MAX
		jeq	error_overflow

		; Mise à jour de la table
		; ldy	flow_stack
		lda	#$00
		sta	if_stack_syntax,y

		; Calcul adresse pointeur dans la table
		clc
		lda	if_ptr
		adc	#.sizeof(if_item)
		sta	if_ptr
		cmp	#(IF_MAX * .sizeof(if_item))
		bcs	error_overflow

		; Conserve le pointeur dans la pile
		sta	if_stack,y

	; [ original sans while/wend
		; On ne conserve que le numéro de ligne pour servir de clé
		tay
		lda	linenum
		sta	if_table+if_item::if_line,y
		lda	linenum+1
		sta	if_table+if_item::if_line+1,y
	; ]
	; [ Ajout
		txa
		sta	if_table+if_item::token,y

		; Sauvegarde l'offset de la ligne suivante
		; Corection fpos_prev-1, à voir pourquoi il faut le faire
		; (cf fgets)
		sec
		lda	fpos_prev
		sbc	#$01
		sta	if_table+if_item::if_offset,y
		lda	fpos_prev+1
		sbc	#$00
		sta	if_table+if_item::if_offset+1,y
		lda	fpos_prev+2
		sbc	#$00
		sta	if_table+if_item::if_offset+2,y
		lda	fpos_prev+3
		sbc	#$00
		sta	if_table+if_item::if_offset+3,y
	; ]

;		lda	#$ff
;		sta	if_flag
		jmp	loop

	else:
		cmp	#TOKEN_ELSE
		bne	endif

		; Underflow
		ldy	flow_stack
		beq	error_unexpected_else

		lda	if_stack_syntax,y
		bne	error_unexpected_else

		lda	#$01
		sta	if_stack_syntax,y

		; Mise à jour de la table
		lda	#if_item::else_line
		jsr	update_table
		jmp	loop

	endif:
		cmp	#TOKEN_ENDIF
		beq	endif1

		cmp	#TOKEN_WEND2
		jne	loop

	endif1:
		; Underflow
		ldy	flow_stack
		beq	error_unexpected_endif

		lda	if_stack_syntax,y
		cmp	#$02
		bcs	error_unexpected_endif

;		lda	if_flag
;		beq	error_no_if

		lda	#$02
		sta	if_stack_syntax,y

		; Mise à jour de la table
		lda	#if_item::endif_line
		jsr	update_table

		dec	flow_stack
;		lda	#$00
;		sta	if_flag
		jmp	loop

	error_overflow:
		prints	"\rtoo many IF/ENDIF line "
		jmp	exit_err

	error_label:
		crlf
		prints	"\rlabel table full"
		jmp	exit_err

	error_unexpected_else:
;		crlf
;		jsr	print_linenumber
;		cputc	':'
;		print	submit_line
;		crlf
		prints	"\runexpected else line "
		jmp	exit_err

	error_unexpected_endif:
		prints	"\runexpected endif line "

	exit_err:
		jsr	print_linenum

	error10:
		crlf
		; 10: Syntax error.
		lda	#10
		sec
		rts

	end:
	.if ::VERBOSE_LEVEL > 0
		crlf
	.endif
		; Vérifie si tous les IF ont un ENDIF
		lda	flow_stack
		beq	exit_ok

		; Récupère la ligne du if incomplet
		tay
		lda	if_stack,y
		tay
		lda	if_table+if_item::if_line,y
		sta	linenum
		lda	if_table+if_item::if_line+1,y
		sta	linenum+1
		lda	if_table+if_item::token,y
		pha
		jsr	print_linenum
		pla
		cmp	#TOKEN_IF
		bne	while_err

		prints	": IF without ENDIF\r\n"
		jmp	err_next

	while_err:
		prints	": DO WHILE without ENDDO\r\n"

	err_next:
		dec	flow_stack
		bne	end
		beq	error10

	exit_ok:
;	.if ::VERBOSE_LEVEL > 1
;		crlf
;		crlf
;		jsr	cmnd_dump
;	.endif

		; [ repris de cmd_chain.s/reset
		jsr	buffer_reset

		; Initialise stack_ptr = 0
		jsr	file_empty_stack

		; Numéro de ligne du fichier batch
		lda	#$00
		sta	linenum
		sta	linenum+1

		; Initialise le pointeur de la pile
		sta	flow_stack

		; Indique qu'on a trouvé tous les labels
		sta	forward_label

		; Rewind
		ldy	#$03
	rewind_loop:
		sta	file_fpos,y
		sta	fpos_text,y
		dey
		bpl	rewind_loop

		; Pas de fseek (le fichier est fermé)
		; jsr	fseek

;	error:
		clc
		rts

	if_flag:
		.byte	$00
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- A: offset dans if_item
; Sortie:
;	- A: modifié
;	- X: inchangé
;	- Y: inchangé
;
; Variables:
;	Modifiées:
;		- if_table
;	Utilisées:
;		- if_stack
;		- linenum
;		- fpos
;
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc update_table
		clc
		ldy	flow_stack
		adc	if_stack,y
		tay

		; Sauvegarde le numéro de la ligne
		; (utile uniquement pour les messages d'erreurs)
;		php
;		sed
		lda	linenum
;		adc	#$01
		sta	if_table,y
		lda	linenum+1
;		adc	#$00
		sta	if_table+1,y
;		plp

		; Sauvegarde l'offset de la ligne suivante
		lda	fpos_text
		sta	if_table+2,y
		lda	fpos_text+1
		sta	if_table+3,y
		lda	fpos_text+2
		sta	if_table+4,y
		lda	fpos_text+3
		sta	if_table+5,y

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
; /!\ Ne remonte pas d'erreur dans le cas suivant (il manque un ENDTEXT)
; TEXT
;	...
; TEXT
;	...
; ENDTEXT
;----------------------------------------------------------------------
.proc skip_text
	loop:
                lda     #<submit_line
                ldy     #>submit_line
                ldx     #LINE_MAX_SIZE
		jsr	fgets
		bcs	eof

		; Saute les espaces en début de ligne
		ldx	#$00
		jsr	skip_spaces
		lda	submit_line,x
		; Ligne vide?
		beq	loop

		; Case insensitive
		clc
                lda     #<scan_tbl
                ldy     #>scan_tbl
		jsr	_find_cmnd
		bcs	loop

		; Ici A: n° du token
		cmp	#TOKEN_ENDTEXT
		bne	loop

	end:
		clc

	eof:
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
.proc print_linenum
;		lda	linenum+1
;		jsr	PrintHexByte
;		lda	linenum
;		jsr	PrintHexByte
		print_int	(linenum), 3
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A,Y: Modifiés
;	X  : Inchangé
;	V: forcé à 0
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
; /!\ ATTENTION: modification du flag V par ADC
;                on force V=0 en sortie
;----------------------------------------------------------------------
.proc push_if
		; TODO: Vérifier que la ligne n'est pas déjà au sommet
		; de la pile (cas des boucles)?
.if 1
		ldy	flow_stack
		beq	loop

		lda	if_stack,y
		tay

		lda	if_table+if_item::if_line,y
		cmp	linenum
		bne	push

		lda	if_table+if_item::if_line+1,y
		cmp	linenum+1
		beq	end
.endif
		; linenum = n° de ligne à trouver dans la table
	push:
		ldy	#$00
		; ldx	#$00

	loop:
		cpy	if_ptr
		beq	@ok
		bcs	err_notfound

	@ok:
		lda	if_table,y
		cmp	linenum
		bne	next
		lda	if_table+1,y
		cmp	linenum+1
		beq	found
	next:
		; /!\ ATTENTION: modification possible du flag V par ADC
		clc
		tya
		adc	#.sizeof(if_item)
		tay
		; inx
		bne	loop

	err_notfound:
		sec
		lda	#ENOENT
		rts

	found:
		; Y = offset dans la table
		inc	flow_stack
		tya
		ldy	flow_stack
		cpy	#IF_MAX
		bcs	err_ovf

		sta	if_stack,y

	end:
		; /!\ Force V=0, nécessaire
		clv

		clc
		lda	#EOK
		rts

	err_ovf:
		; 103: DOs nested too deep.
		lda	#ENOMEM
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
.proc pop_else
		ldy	flow_stack
		beq	err_empty

		lda	if_stack,y
		tay

		; Numéro de ligne du bloc else
		lda	if_table+if_item::else_line,y
		sta	linenum
		lda	if_table+if_item::else_line+1,y
		sta	linenum+1
		; Si numéro de ligne == 0 alors il n'y a pas de else => endif
		ora	linenum
		beq	pop_endif

		; Offset du bloc else
		lda	if_table+if_item::else_offset,y
		sta	file_fpos
		sta	fpos_text
		lda	if_table+if_item::else_offset+1,y
		sta	file_fpos+1
		sta	fpos_text+1
		lda	if_table+if_item::else_offset+2,y
		sta	file_fpos+2
		sta	fpos_text+2
		lda	if_table+if_item::else_offset+3,y
		sta	file_fpos+3
		sta	fpos_text+3

		jsr	buffer_reset
		clc
		rts

	err_empty:
		sec
		lda	#ERANGE
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
.proc pop_endif
		ldy	flow_stack
		beq	err_empty

		lda	if_stack,y
		tay

		; Numéro de ligne du bloc endif
		lda	if_table+if_item::endif_line,y
		sta	linenum
		lda	if_table+if_item::endif_line+1,y
		sta	linenum+1

		; Offset du bloc endif
		lda	if_table+if_item::endif_offset,y
		sta	file_fpos
		sta	fpos_text
		lda	if_table+if_item::endif_offset+1,y
		sta	file_fpos+1
		sta	fpos_text+1
		lda	if_table+if_item::endif_offset+2,y
		sta	file_fpos+2
		sta	fpos_text+2
		lda	if_table+if_item::endif_offset+3,y
		sta	file_fpos+3
		sta	fpos_text+3

		dec	flow_stack

		jsr	buffer_reset
		clc
		rts

	err_empty:
		sec
		lda	#ERANGE
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	C: 0-> WEND, 1-> LOOP (on cherche le WHILE le plus récent)
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
.proc flow_loop
		ldy	flow_stack
		beq	err_empty

	unstack:
		lda	if_stack,y
		tay

		bcc	loop

		lda	if_table+if_item::token,y
		cmp	#TOKEN_WHILE
		beq	loop

		dec	flow_stack
		sec
		beq	err_noWhile

		ldy	flow_stack
		bcs	unstack

	loop:
		; Numéro de ligne du bloc if
		; -1 parce que fgets va incrémenter linenum
		sec
		lda	if_table+if_item::if_line,y
		sbc	#$01
		sta	linenum
		lda	if_table+if_item::if_line+1,y
		sbc	#$00
		sta	linenum+1

		; Offset du bloc if
		lda	if_table+if_item::if_offset,y
		sta	file_fpos
		sta	fpos_text
		lda	if_table+if_item::if_offset+1,y
		sta	file_fpos+1
		sta	fpos_text+1
		lda	if_table+if_item::if_offset+2,y
		sta	file_fpos+2
		sta	fpos_text+2
		lda	if_table+if_item::if_offset+3,y
		sta	file_fpos+3
		sta	fpos_text+3

		dec	flow_stack

		jsr	buffer_reset
		clc
		rts

	err_empty:
		lda	#ERANGE
		sec
		rts

	err_noWhile:
		; dBase III ne semble pas remonter d'erreur si on fait un LOOP en dehors d'une boucle
		; mais stoppe le programme
		lda	#ERANGE
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	C: 0-> WEND, 1-> LOOP (on cherche le WHILE le plus récent)
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
.proc flow_exit
		ldy	flow_stack
		beq	err_empty

	unstack:
		lda	if_stack,y
		tay

		lda	if_table+if_item::token,y
		cmp	#TOKEN_WHILE
		beq	exit

		dec	flow_stack
		sec
		beq	err_noWhile

		ldy	flow_stack
		bcs	unstack

	exit:
		jmp	pop_endif

	err_empty:
		lda	#ERANGE
		sec
		rts

	err_noWhile:
		; dBase III ne semble pas remonter d'erreur si on fait un LOOP en dehors d'une boucle
		; mais stoppe le programme
		lda	#ERANGE
		rts
.endproc

