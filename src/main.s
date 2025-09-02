	;.res 68, $ea	; 12 588 => Ok

	; => KO

	; .res 86, $ea	; 12 608 => Ok

	; 11419 (12844) => ok
	; ... => ko
	; 11437 (12865) => ok

	;  (13356)
	; ... => ko
	;  (13374)

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
.include "keyboard.inc"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import entlen
.import tabase
.import keylen
.import keydup

; From readline
.import readline
.import readline_set_option
.import readline_set_callback

; Spécifique submit
; [
.import submit
.import cmnd_label
; ]

; From yacc
.import interpret
.import error_code

; From get_tokesn
.import skip_spaces

.ifdef USE_LINKEDLIST
	.import refbase
.endif

.import external_command

; From get_args.s
.import init_argv
.import get_argv

; From fgets.s
.import fgets
.import linenum

; From file.s
.import open
.import close
.import fgetline

; From cmnd_run.s
.import set_errorlevel

; From cmnd_procedure
.import reset_labels
;.import forward_label
;.import label_num
;.import label_ofs

; From cmnd_set
.import cmnd_set

; From lex_common
.import opt_num

; From get_off
.import on_off_flag

; From scan.s
.import scan

; From cmnd_getkey.s
.import set_keyvar

; From check_kernel_version
;.import check_kernel_version

.if HAS_ON_ERROR
	; From on_error.s
	.import on_error
.endif

; From math.s
.import init_aexp

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export _main
.exportzp _argv
.export _argc

; Pour yacc
.exportzp line_ptr
;.export ident_dst

; Pour cmnds
.export vars_data_index
.export vars_index
.export vars_datas
.export global_cursor

; Pour utils
.export submit_line

; Mode interractif
.export input_mode

; Pour fgets
.export fp

.export entry

.export version

; Pour fn_message()
.export fExternal_error

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
OPT_CURSOR = 25

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short _argv
		unsigned short ptr
		unsigned short work_ptr
		unsigned short line_ptr

	.segment "DATA"
;		unsigned short _argv
		unsigned char _argc
		unsigned short argn

		unsigned char save_a
		unsigned char save_y
;		unsigned char start_y

	.ifdef WITH_HISTORY
			; Historique
			unsigned char history[LINE_MAX_SIZE*HISTORY_SIZE]
			unsigned short history_ptr
			unsigned char history_index
			unsigned char history_current
	.endif

		; Mode interractif (0)  ou non (1)
		unsigned char input_mode

		; File pointer
		unsigned short fp

		; Flag pour l'utilisation de dbaserr
		unsigned char fExternal_error

		; Pour find_cmnd
                unsigned char submit_line[LINE_MAX_SIZE]

		; Pour cmnd_set
		unsigned char global_cursor

;		unsigned char ident_dst[IDENT_LEN+1]
		; index[]: un pointeur par lettre de l'alphabet
		; base[] : place pour 17 éléments (17*11+1)

		unsigned char entry[ENTRY_LEN]

	.ifdef USE_LINKEDLIST
		unsigned short index[26]
		unsigned char base[VARS_MAX*ST_ENTRYLEN+1]
		unsigned char vars_index

		unsigned char vars_datas[VARS_DATALEN*VARS_MAX]
		unsigned short vars_data_index

	.else
		; Application
		unsigned char base[VARS_MAX*ST_ENTRYLEN+1]
		unsigned char vars_index

		unsigned char vars_datas[VARS_DATALEN*VARS_MAX]
		unsigned short vars_data_index
	.endif
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		noarg_msg:
			.asciiz "Aucun argument\r\n"

		version:
			.asciiz	"oBASE version 1.0"
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;.res 18, $ea

;.res 38,$ea

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
.proc _main
;		jsr	check_kernel_version

	.ifndef SUBMIT
		; cursor	on
		lda	#OPT_CURSOR
		sta	opt_num
		sta	on_off_flag
		jsr	cmnd_set
	.else
		; lda	#$00
		lda	#$ff
		sta	global_cursor
	.endif
		; Mode interractif
		lda	#$00
		sta	input_mode

		; Utilise dbaserr pour les messages d'erreur
		lda	#$01
		sta	fExternal_error

	.ifdef WITH_HISTORY
			sta	history_index
			sta	history_current
			lda	#<history
			sta	history_ptr
			lda	#>history
			sta	history_ptr+1
	.endif

		jsr	init_tables

		; Initialise errorlevel
		lda	#$00
		jsr	set_errorlevel

	.ifdef SUBMIT
		; Initialise key
		lda	#$00
		jsr	set_keyvar
	.endif

	.ifdef WITH_HISTORY
			on = 1
			set_option	return_if_cc, on
			set_callback	KEY_UP, key_history
			set_callback	KEY_DOWN, key_history
	.endif

		initmainargs _argv, , 1
		; [ compatibilité submit $0=<nom_du_pgm>
		; ]
		; [ sinon il faut sauter le premier paramètre
;		sta	ptr
;		sty	ptr+1
;		; On saute les ' ' au début de la ligne
;		ldy	#$ff
;	skip_sp:
;		iny
;		lda	(ptr),y
;		beq	no_param
;		cmp	#' '
;		beq	skip_sp
;
;		; On saute le premier paramètre (dbase2)
;		dey
;	skip_p0:
;		iny
;		lda	(ptr),y
;		beq	no_param
;		cmp	#' '
;		bne	skip_p0
;
;		; Ajuste le pointeur
;		tya
;		ldy	ptr+1
;		clc
;		adc	ptr
;		sta	ptr
;		bcc	init_arg
;		iny
;	init_arg:
		; ]
		jsr	init_argv
	no_param:
		sta	_argc
		mfree	(_argv)

		lda	_argc
		; [ Compatibilité submit
		cmp	#$02
		; ]
		; [ sinon
;		cmp	#$01
		; ]
		bcc	loop

		; [ Compatibilité submit
		ldx	#$01
		; ]
		; [ sinon
;		ldx	#$00
		; ]
		jsr	get_argv

		jsr	open
		bcs	loop

		; copie fp dans input_mode
		; /!\ suppose que fp ne peur pas être nul
		sta	input_mode

		; On peut refermer le fichier, il sera ouvert par fgetline
		jsr	close

		; Recherche des blocs IF/ELSE/ENDIF
		jsr	scan
		; php

		; On vérifie si le scan à remonté une erreur
		; plp
		lda	#$ff
		bcs	exit_err

	loop:
		lda	global_cursor
		beq	@cursor_off
		cursor	on
		jmp	@skip
	@cursor_off:
		cursor	off

	@skip:
		lda	input_mode
		beq	stdio

		; Ctrl+C?
		;  4 End of file encountered.
		; 51 End of file or error on keyboard input.
		; (Il faudrait 1, 8 *** INTERRUPTED ***)
		lda	#51
		asl	KBDCTC
		bcs	exit_err

		ldx	#LINE_MAX_SIZE
		jsr	fgetline
		sta	line_ptr
		sty	line_ptr+1
		bcc	go
		; Transfère le code erreur dans A
		txa
		ldy	#$00
		bcs	exit_err

	stdio:
		; cursor	on

		; /?\ La macro ne considère pas LINE_MAX_SIZE comme un constante,
		; il faut préciser ::LINE_MAX_SIZE !!!
		;input	"dBaseII>", LINE_MAX_SIZE, line_ptr
		input	PROMPT, ::LINE_MAX_SIZE, line_ptr

	.ifdef WITH_HISTORY
			bmi	up_down
	.endif
		; Ligne vide?
		beq	loop

	.ifdef WITH_HISTORY
			lda	history_index
			sta	history_current
	.endif

	go:
		; [ ECHO ON
		; print	(line_ptr)
		; crlf
		; ]

		; Spécifique submit
		; [
		jsr	submit
		bcs	error
		; ]

		lda	line_ptr
		ldx	line_ptr+1
		ldy	#$00
		jsr	skip_spaces

		; Ligne vide
		lda	(line_ptr),y
	beq_loop:
		beq	loop

	.ifdef WITH_HISTORY
			jsr	add_to_history
	.endif

		; Si le premier caractère est un '*' (ou ';') c'est un commentaire
		cmp	#REM_CHR
		beq	loop

	.ifdef SUBMIT
		; [ Compatibilité submit
		cmp	#'#'
		beq	loop
		; ]
	.endif

	.ifdef LABEL_CHR
		; [ Spécifique submit (équivalent de PROCEDURE)
		cmp	#LABEL_CHR
		bne	go_interpret
		jsr	cmnd_label
		bcc	loop
		bcs	exit_err
		; ]
	.endif

	go_interpret:
;		lda	line_ptr
;		ldx	line_ptr+1
		jsr	interpret
		; C=0->Ok
		; C=1 et V=0 ->Erreur (A=code erreur, Y=offset de l'erreur)
		; C=1 et V=1 -> pas une affectation, on peut tenter la commande externe

		; Note: on n'est pas nécessairement arrivé à la fin de la ligne
		; TODO: vérifier qu'on est bien en fin de ligne (actuellement
		;       fait par interpret)
		bcc	loop
		; Si on ne veut pas de commande externe
		; [
		bcs	exit_err
		; ]
		; sinon
		; [
		; bvc	exit_err
		; ;bvs	external_cmnd
		; external_cmnd:
		; ...
		; ]

	.ifdef WITH_HISTORY
		up_down:
			; V: 1-> Up, 0-> Down
			bvs	hist_back
			bvc	hist_next
	.endif

	exit_err:
		cmp	#$ff
		beq	end

	error:
		sta	error_code

	.ifdef HAS_ON_ERROR
		ldx	on_error
		bne	do_on_error
	.endif

		jsr	disp_error
;		set_option	FILL_BUFFER, line_ptr
		lda	input_mode
		beq	loop
		jsr	close
		lda	#$00
		sta	input_mode

	.ifndef SUBMIT
		; /?\ boucle uniquement si en mode interactif?
		beq	beq_loop
	.else
		; Compatibilité submit: on sort en cas d'erreur
	.endif

	end:
		crlf
		; TODO: Renvoyer un code erreur au processus père
		; /!\ error_code contient le dernier code erreur et non le code
		;     erreur de la dernière instuction exécutée
	.ifndef SUBMIT
		lda	#EOK
	.else
		lda	error_code
	.endif
		ldx	#$00
		rts

	.ifdef HAS_ON_ERROR
	do_on_error:
		ldy	#$ff
	on_error_loop:
		iny
		lda	on_error,y
		sta	(line_ptr),y
		bne	on_error_loop
		beq	go
	.endif

	no_on_error:

	.ifdef WITH_HISTORY
		hist_back:
			lda	history_current
			beq	end_history
			jmp	loop

		hist_next:
			lda	history_current
			cmp	history_index
			beq	end_history
			inc	history_current
			jmp	loop

		end_history:
			cputc	$07
			cputc	$0d
			cputc	$0e
			jmp	loop
	.endif

.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	AY: adresse du tampon readline
;	X : code touche
; Sortie:
;	A,X,Y: inchangés
;	C: 0
;	N: 1
;	V: 0->Down, 1->Up
;	Z: 0
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.ifdef WITH_HISTORY
	.proc key_history
			;			N V - D B I Z C
			;	Up	:	1 1         x 0         bmi     fleches
			;	Down	:	1 0         x 0

			cpx     #KEY_UP
			bcc     down
			; ici Z=1, C=1, V=0, N=0 pour KEY_UP
		up:
			clc
			; cpx #xx => $c0 xx (N=1, V=1)
			bit     key_history
		down:
			; ici N=1, C=0, V=0 pour KEY_DOWN
		end:
			rts

	.endproc
.endif

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
.proc init_tables
	.ifdef USE_LINKEDLIST
		lda	#<index
		ldy	#>index
		sta	refbas
		sty	refbas+1
	.endif

		; Initialise les pointeurs pour la table des labels
		jsr	reset_labels

		; Initialise la table des variables
		lda	#<base
		ldy	#>base
		sta	tabase
		sty	tabase+1

		lda	#ENTRY_LEN
		sta	entlen

	.ifdef USE_LINKEDLIST
		; Marker EOT
		lda	#$7c
		sta	base

		;
		; Initialise le répertoire
		; Toutes les entrées pointent vers le premier octet de la base
		; qui contient le marqueur EOT
		;
		; ($34 = 52 = 26*2)
		;
		ldx	#$00
	loop:
		lda	#<base
		sta	index,x
		inx
		lda	#>base
		sta	index,x
		inx
		cpx	#$34
		bne	loop
	.else
		lda	#$00
		sta	base+VARS_MAX*ST_ENTRYLEN
	.endif

		; Longueur de la clé
		lda	#IDENT_LEN
		sta	keylen

		; Autorise l'écrasement d'une clé
		lda	#$ff
		sta	keydup

		; Nombre de variables dans la table
		lda	#$00
		sta	vars_index

		; Pointeur vers la table des données
		lda	#<vars_datas
		ldy	#>vars_datas
		sta	vars_data_index
		sty	vars_data_index+1

		; [
.if 0
.import var_new
.importzp object
.import clear_entry
		jsr	clear_entry
		lda	#'A'
		sta	entry+st_entry::name

		; Type: numérique
		lda	#'N'
		sta	entry+st_entry::type

		; Longueur: 4
		lda	#$04
		sta	entry+st_entry::len

		; Valeur 1234
		lda	#$12
		sta	entry+st_entry::data_ptr
		lda	#$34
		sta	entry+st_entry::data_ptr+1

		lda	#<entry
		sta	object
		lda	#>entry
		sta	object+1
		jsr	var_new
		inc	vars_index
		; ]
.endif
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
.proc disp_error
	error:
		sta	save_a
		sty	save_y

.if 0
		; Affiche le message d'erreur avant la ligne

		crlf

		lda	save_a

		; TODO: tester une option pour savoir si on doit utiliser dbaserr
		;       pour afficher le message d'erreur et non son numéro
		jsr	external_command
		bcc	disp_err_pos

		; Si on est ici c'est soit parce que l'option "use dbaserr" est off
		; soit qu'on a une erreur lors de l'exécution de dbaserr, donc
		; on peut orcer l'option à OFF

		prints	"*** ERROR "
		lda	save_a
		ldy	#$00
		ldx	#$02
		.byte	$00, XDECIM
		prints	" ***"
.endif

	disp_err_pos:
		crlf

		; [ Affiche le n° de ligne
		lda	DEFAFF
		pha

		lda	#'0'
		sta	DEFAFF
		lda	linenum
		ldy	linenum+1
		ldx	#$02
		.byte	$00, XDECIM

		pla
		sta	DEFAFF

		cputc	':'
		; ]

		print	(line_ptr)
		crlf

		; Position du curseur
		; [ Avec n° de ligne
		lda	save_y
		clc
		adc	#05
		tay
		; ]
		; [ sans n° de ligne
		; ldy	save_y
		; beq	error_end
		; ]

	error_loop:
		cputc	' '
		dey
		bne	error_loop

	error_end:
		cputc	'^'
		crlf

		; Utilisation de dbaserr?
		lda	fExternal_error
		beq	internal_error

		; Affiche le message d'erreur après la ligne
		lda	save_a
		jsr	external_command
		bcc	end

	internal_error:
		; Si on est ici c'est soit parce que l'option "use dbaserr" est off
		; soit qu'on a une erreur lors de l'exécution de dbaserr, donc
		; on peut forcer l'option à OFF
		lda	#$00
		sta	fExternal_error

		prints	"*** ERROR "
		lda	save_a
		ldy	#$00
		ldx	#$02
		.byte	$00, XDECIM
		prints	" ***"

	end:
		crlf
		crlf

		;lda	save_a
;
		;jsr	external_command
;
;		; L'exécution de la commande a supprimer le curseur
		; cursor	on

		clc
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
.ifdef WITH_HISTORY
	.proc add_to_history
			sty	save_y

			lda	history_ptr
			sta	ptr
			lda	history_ptr+1
			sta	ptr+1

			ldy	#$ff
		loop:
			iny
			lda	(line_ptr),y
			sta	(ptr),y
			bne	loop

			; Dernière entrée de l'historique?
			ldx	history_index
			inx
			cpx	#HISTORY_SIZE
			bne	next

			; Oui, on revient à la première
			lda	#$00
			sta	history_index
			lda	#<history
			sta	history_ptr
			lda	#>history
			sta	history_ptr+1

			ldy	save_y
			rts

		next:
			stx	history_index

			clc
			lda	ptr
			adc	#LINE_MAX_SIZE
			sta	history_ptr
			lda	#$00
			adc	ptr+1
			sta	history_ptr+1

			ldy	save_y
			rts
	.endproc
.endif

