;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import cmnd_input_sub

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export date_fmt
.export opt_to

;----------------------------------------------------------------------
;                               Variables
;----------------------------------------------------------------------
.pushseg

        .segment "DATA"
                ;unsigned char date_fmt
                date_fmt:
                        .byte $2f | $80 | $10
                        ;       /   FR    CENTURY ON
.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"

		; --------------------------------------------------------------
		;			Instructions
		; --------------------------------------------------------------
		; Liste des instructions			; Equivalent submit
		cmnd_table:
			string80	"TEXT"			; text... endtext
			string80	"EXIT"			; exit (ajouter paramètre <n>)
			string80	"PAUSE"			; wait (getkey / pause)
			string80	"INPUT"			; accept
			string80	"CLS"			; clear
			string80	"ECHO -N"		; ??
;				TOKEN_PRINT_NOCR = 5
			string80	"ECHO"			; ?
;				TOKEN_PRINT = 6

			string80	"RESTORE"		; restore from
			string80	"SAVE"			; save to

			string80	"IIF"			; if

;			string80	"RUN"
;			string80	"!"			; Alias de run

			string80	"@"			; @

			string80	"REM"			; rem [* ...]

;			string80	"DUMP"			; TEST


			; [ Spécifique submit
			string80	"GOTO"			; goto
			string80	"CALL"			; call
			string80	"RETURN"		; return
			; ]
								; cd
								; choice
			string80	"CHAIN"			; chain

;			string80	"DIR"
			string80	"TYPE"

			string80	"GETKEY"		; Si on veut la même syntaxe que submit, sinon utiliser PAUSE/WAIT "" TO KEY

			string80	"EXEC"

			.byte	$00

		.out .sprintf("\t*** cmnd_table: %d", *-cmnd_table)

		; Règle de chaque instruction (dans l'ordre de cmnd_table)
		yacc_tbl:
			.word	RULE_TEXT
			.word	RULE_QUIT
			.word	RULE_WAIT
			.word	RULE_INPUT_SUB
			.word	RULE_CLEAR
			.word	RULE_PRINT
			.word	RULE_PRINT

			.word	RULE_RESTORE
			.word	RULE_SAVE

			.word	RULE_IIF

;			.word	RULE_RUN
;			.word	RULE_RUN

			.word	RULE_AT

			.word	RULE_NOTE

;			.word	RULE_DUMP

			.word	RULE_GOTO
			.word	RULE_CALL
			.word	RULE_RETURN

			.word	RULE_DO

;			.word	RULE_DIR
			.word	RULE_TYPE

			.word	RULE_GETKEY

			.word	RULE_EXEC

		; Liste des cibles possibles des règles (dernier octet d'une règle)
		cmnd_addr:
			.addr	cmnd_text
			.addr	cmnd_quit
			.addr	cmnd_wait
			.addr	cmnd_input_sub
			.addr	cmnd_clear
			.addr	cmnd_print

			.addr	cmnd_restore
			.addr	cmnd_save

			.addr	cmnd_iif

;			.addr	cmnd_run
;			;.addr	cmnd_run			; !
			.addr	cmnd_at

;			.addr	cmnd_dump

			.addr	cmnd_goto
			.addr	cmnd_call
			.addr	cmnd_return

			.addr	cmnd_do

;			.addr	cmnd_dir
			.addr	cmnd_type

			.addr	cmnd_getkey

			.addr	cmnd_exec

		; Commandes dans l'ordre de cmnd_addr
		.enum CMND
			TEXT
			QUIT
			WAIT
			INPUT_SUB
			CLEAR
			PRINT

			RESTORE
			SAVE

			IIF

;			RUN
;			; RUN					; !

			AT
;			DUMP

			GOTO
			CALL
			RETURN

			DO

;			DIR
			TYPE

			GETKEY

			EXEC

			NOOP =$ff
		.endenum


		; Règles syntaxiques
		syn_tbl:
			; On peut fusionner les 3 règles suivantes, dans ce cas
			; CMND:XXX peut faire la différence entre les 2 instructions
			; en regardant cmnd_number
			RULE_TEXT:
				.byte	EOL, CMND::TEXT

;			RULE_CANCEL:
;				.byte	EOL, CMND::CANCEL

			RULE_QUIT:
				.byte	EXPR_NZ, EOL, CMND::QUIT


;			RULE_SET:
;				;.byte	OPT, ON_OFF, EOL, CMND::SET
;				.byte	OPT, <set_opt, >set_opt, ON_OFF, EOL, CMND::SET

			RULE_WAIT:
				.byte	STRINGZ, TO_IDENTZ, EOL, CMND::WAIT


			; On peut fusionner les 2 règles suivantes, dans ce cas
			; CMND:XXX peut faire la différence entre les 2 instructions
			; en regardant cmnd_number
			RULE_INPUT_SUB:
				;.byte	STRINGZ, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::ACCEPT
				.byte	STRINGZ, ','+$80, EXPR_N, ','+$80, IDENT, EOL, CMND::INPUT_SUB

;			RULE_INPUT:
;				.byte	STRINGZ, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::INPUT


			RULE_CLEAR:
				;.byte	EOL, CMND::CLEAR
				.byte	OPTZ, <opt_clear, >opt_clear, EOL, CMND::CLEAR


;			RULE_STORE:
;				; .byte	EXPR, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::STORE
;				.byte	TERM, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::STORE

;			RULE_DISPLAY:
;				.byte	IDENT, EOL, CMND::DISPLAY


			RULE_PRINT:
				; .byte	EXPR, EOL, CMND::PRINT
				; .byte	TERM, EOL, CMND::PRINT
				.byte	TO_EOL, EOL, CMND::PRINT

			RULE_RESTORE:
				.byte	LITERAL, "FRO",'M'+$80, FILENAME, EOL, CMND::RESTORE

			RULE_SAVE:
				.byte	LITERAL, "T",'O'+$80, FILENAME, EOL, CMND::SAVE


			RULE_IIF:
				; Modifier la règle: EXPR_L, EOI, CMND::IF
				; .byte	EXPR1, CMP_OP, EXPR, EOI, CMND::IIF

				; .byte EXPR_L, EOI, CMND::IIF
				.byte EXPR_L, LITERAL, "THE",'N'+$80, EOI, CMND::IIF

;			RULE_SET_DATE:
;				; .byte	DATE_FMT, EOL, CMND::SET_DATE
;				.byte	OPT, <opt_date_fmt, >opt_date_fmt, EOL, CMND::SET_DATE

;			RULE_RUN:
;				;.byte	STRING, EOL, CMND::RUN
;				.byte	TO_EOL, EOL, CMND::RUN

			RULE_AT:
				; Compatibilité submit
				.byte	EXPR_N1, ','+$80, EXPR_N, EOI, CMND::AT
				;.byte	EXPR_N1, ','+$80, EXPR_N, EOL, CMND::AT

			RULE_NOTE:
				.byte	STRING, EOL, CMND::NOOP

;			RULE_PROCEDURE:
;				.byte	IDENT, EOL, CMND::PROCEDURE

;			RULE_DUMP:
;				.byte	EOL, CMND::DUMP

;			RULE_PARAMETERS:
;				; Si on veut que la commande soit directement exécutée
;				; .byte	VARGS, EOL, CMND::NOOP
;				; Si on veut que cmnd_parameters puisse vérifier qu'on est
;				; bien dans une prcoédure
;				.byte	TO_EOL, EOL, CMND::PARAMETERS

			RULE_GOTO:
				.byte	IDENT, EOL, CMND::GOTO

			RULE_CALL:
				.byte	IDENT, EOL, CMND::CALL

			RULE_RETURN:
				.byte	EOL, CMND::RETURN

			RULE_DO:
				; .byte	FILENAME, LITERAL, "WIT", 'H'+$80, TO_EOL, EOL, CMND::DO
				.byte	FILENAME, OPTZ, <opt_do, >opt_do, TO_EOL, EOL, CMND::DO

;			RULE_DIR:
;				; TODO: Ajouter FILENAMEZ?
;				.byte	FILENAMEZ, EOL, CMND::DIR

			RULE_TYPE:
				.byte	FILENAME, EOL, CMND::TYPE

;			RULE_MODIFY:
;				.byte	OPT, <opt_modify, >opt_modify, FILENAME,EOL, CMND::MODIFY

			RULE_GETKEY:
				.byte	EOL, CMND::GETKEY

			RULE_EXEC:
				.byte	TO_EOL, EOL, CMND::EXEC


		.out .sprintf("\t*** syn_tbl: %d", *-syn_tbl)
		.if ::LOOKUP_TABLE_PAGE
			; [ Si les tables sont limitées à 256 caractères maxy
			.assert *-syn_tbl < $100, error , "Table too large"
			; ]
		.endif
		; --------------------------------------------------------------
		;			Fonctions
		; --------------------------------------------------------------
		; Liste des instructions			; Equivalent submit
		func_table:
.if 0
			; Argument numérique
			string80	"CHR("
			string80	"INT("
			string80	"SPACE("
			string80	"STR("
			string80	"HEX("
			string80	"OCT("
			string80	"BIN("
			string80	"ABS("
			string80	"PEEK("			; Supplément perso
				; TOKEN_PEEK=8			; Défini dans dbase.inc
			string80	"DEEK("			; Supplément perso

			; Argument chaine
			string80	"LEN("
			string80	"TRIM("
			string80	"LTRIM("
			string80	"RTRIM("
			string80	"VAL("
			string80	"UPPER("
			string80	"LOWER("
			string80	"ISUPPER("
			string80	"ISLOWER("
			string80	"FILE("
			string80	"GETENV("		; pwd [getenv("PATH")]

			string80	"ASC("

			; Argument expression
			string80	"TYPE("
				TOKEN_TYPE=22
			string80	"ISALPHA("

			; Arguments: chaine, numérique
			string80	"LEFT("
			string80	"RIGHT("
			string80	"REPLICATE("

			; Aucun argument
			string80	"ROW("
			string80	"COL("
			string80	"DISKSPACE("
			string80	"ERROR("
			string80	"MESSAGE("
			string80	"OS("
			string80	"TIME("
			string80	"VERSION("
			string80	"INKEY("

			string80	"DATE("

			; Argument date
			string80	"DTOC("
			string80	"DAY("
			string80	"MONTH("
			string80	"YEAR("
			string80	"DOW("
			string80	"CMONTH("
			string80	"CDOW("

			; Arguments: chaine, chaine
			string80	"AT("

			; Arguments: chaine, numérique, numérique
			string80	"SUBSTR("

			; Arguments: numérique, numérique
			string80	"MAX("
			string80	"MIN("

			string80	"SPEEK("		; Supplément perso

			; Arguments: chaine, numérique, numérique, chaine
			string80	"STUFF("
.endif
			.byte	$00

		.out .sprintf("\t*** func_table: %d", *-func_table)
		.if ::LOOKUP_TABLE_PAGE
			; [ Si les tables sont limitées à 256 caractères maxy
			.assert *-func_table < $100, error , "Table too large"
			; ]
		.endif

		func_addr:
.if 0
			.word	fn_chr
			.word	fn_int
			.word	fn_space
			.word	fn_str
			.word	fn_hex
			.word	fn_oct
			.word	fn_bin
			.word	fn_abs
			.word	fn_peek
			.word	fn_peek			; peek / deek

			.word	fn_len
			.word	fn_trim
			.word	fn_ltrim
			.word	fn_rtrim
			.word	fn_val
			.word	fn_upper
			.word	fn_lower
			.word	fn_isupper
			.word	fn_islower
			.word	fn_file
			.word	fn_getenv

			.word	fn_asc

			.word	fn_type
			.word	fn_isalpha

			.word	fn_left
			.word	fn_right
			.word	fn_replicate

			.word	fn_row
			.word	fn_col
			.word	fn_diskspace
			.word	fn_error
			.word	fn_message
			.word	fn_os
			.word	fn_time
			.word	fn_version
			.word	fn_inkey

			.word	fn_date

			.word	fn_dtoc
			.word	fn_day
			.word	fn_month
			.word	fn_year
			.word	fn_dow
			.word	fn_cmonth
			.word	fn_cdow

			.word	fn_at

			.word	fn_substr

			.word	fn_max
			.word	fn_min

			.word	fn_peek_str

			.word	fn_stuff
.endif
		func_yacc_tbl:
.if 0
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N
			.word	RULE_FN_N

			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C
			.word	RULE_FN_C

			.word	RULE_FN_C

			.word	RULE_FN_X
			.word	RULE_FN_X

			.word	RULE_FN_CN
			.word	RULE_FN_CN
			.word	RULE_FN_CN

			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_
			.word	RULE_FN_

			.word	RULE_FN_

			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT

			.word	RULE_FN_CC

			.word	RULE_FN_CNN

			.word	RULE_FN_NN
			.word	RULE_FN_NN

			.word	RULE_FN_NN

			.word	RULE_FN_CNNC
.endif
		func_syn_tbl:
.if 0
			RULE_FN_:
				.byte	')'+$80, EOI

			RULE_FN_X:
				.byte	EXPR, ')'+$80, EOI

			RULE_FN_N:
				.byte	EXPR_N, ')'+$80, EOI

			RULE_FN_C:
				 .byte	EXPR_C, ')'+$80, EOI
				;.byte	TERM_C, ')'+$80, EOI

			RULE_FN_DT:
				.byte	EXPR_D, ')'+$80, EOI

			RULE_FN_CN:
				; .byte	PARAM_S, ','+$80, PARAM_N, ')'+$80, EOL, CMND::REPLICATE
				.byte	EXPR_C, ','+$80, EXPR_N, ')'+$80, EOI

			RULE_FN_CNN:
				.byte	EXPR_C, ','+$80, EXPR_N1, ','+$80, EXPR_N, ')'+$80, EOI

			RULE_FN_CC:
				.byte	EXPR_C1, ','+$80, EXPR_C, ')'+$80, EOI

			RULE_FN_NN:
				.byte	EXPR_N1, ','+$80, EXPR_N, ')'+$80, EOI

			RULE_FN_CNNC:
				.byte	EXPR_C1, ','+$80, EXPR_N1, ','+$80, EXPR_N, ','+$80, EXPR_C, ')'+$80, EOI
.endif

.if 0
		; --------------------------------------------------------------
		;			SET xxx
		; --------------------------------------------------------------
		set_opt:
			string80	"ALTERNATE"
			string80	"BELL"
			string80	"CARRY"
			string80	"COLON"
			string80	"CONFIRM"
			string80	"CONSOLE"
			string80	"DEBUG"
			string80	"DELETE"
			string80	"ECHO"
			string80	"EJECT"
			string80	"ESCAPE"
			string80	"EXACT"
			string80	"INTENSITY"
			string80	"LINKAGE"
			string80	"PRINT"
			string80	"RAW"
			string80	"SPACE"
			string80	"STEP"
			string80	"TALK"

			string80	"DELETED"
			string80	"DOHISTORY"
			string80	"SAFETY"
			string80	"SCOREBOARD"
			string80	"UNIQUE"

			string80	"CENTURY"
			OPT_CENTURY = 24

			; [ Ajout
			string80	"CURSOR"
			OPT_CURSOR = 25

			.byte	$00

		opt_on_off:
			string80	"OFF"
			string80	"ON"
			.byte	$00
.endif
		opt_to:
			string80	"TO"
			.byte	$00
.if 0
		opt_date_fmt:
			string80	"AMERICAN"	; = mm/jj/aa
			string80	"ANSI"		; = aa.mm.jj
			string80	"BRITISH"	; = jj/mm/aa
			string80	"FRENCH"	; = jj/mm/aa
			string80	"GERMAN"	; = jj.mm/aa
			string80	"ITALIAN"	; = jj-mm-aa
			.byte	$00

		; --------------------------------------------------------------
		;			Date
		; --------------------------------------------------------------
		; Table 12
		days:
			string80	"Dimanche"
			string80	"Lundi"
			string80	"Mardi"
			string80	"Mercredi"
			string80	"Jeudi"
			string80	"Vendredi"
			string80	"Samedi"

		; Table 13
		months:
			string80	"Janvier"
			string80	"Fevrier"
			string80	"Mars"
			string80	"Avril"
			string80	"Mai"
			string80	"Juin"
			string80	"Juillet"
			string80	"Aout"
			string80	"Septembre"
			string80	"Octobre"
			string80	"Novembre"
			string80	"Decembre"

		; --------------------------------------------------------------
		;			DISPLAY
		; --------------------------------------------------------------
		opt_display:
			string80	"FILES"
			string80	"HISTORY"
			string80	"MEMORY"
			string80	"STATUS"
			string80	"STRUCTURE"
			.byte	$00

		; --------------------------------------------------------------
		;			CLEAR
		; --------------------------------------------------------------
		opt_clear:
			string80	"ALL"
			OPT_ALL = $00

			string80	"FIELDS"
			string80	"GETS"
			string80	"MEMORY"
			OPT_MEMORY = $03

			string80	"TYPEAHEAD"
			.byte	$00
.endif
		; --------------------------------------------------------------
		;			DO
		; --------------------------------------------------------------
		opt_do:
			string80	"WITH"
			.byte	$00
.if 0
		; --------------------------------------------------------------
		;			MODIFY
		; --------------------------------------------------------------
		opt_modify:
			string80	"COMMAND"
			string80	"FILE"
			.byte	$00
.endif
		; --------------------------------------------------------------
		;			CLEAR
		; --------------------------------------------------------------
		opt_clear:
			.byte	$00

		; --------------------------------------------------------------
		;		Opérateurs de comparaison
		; --------------------------------------------------------------
		cmp_oper:
			string80	"<"
			string80	">"
			string80	"<>"
			string80	"="
			string80	"<="
			string80	">="
			.byte	$00

		; --------------------------------------------------------------
		;			Environnement
		; --------------------------------------------------------------
		osenv:
			string80	"PATH"
			.byte	$00

		os_default:
			.asciiz	"Orix"

		uname:
			.asciiz	"uname -a"

		; --------------------------------------------------------------
		;				Erreur
		; --------------------------------------------------------------
		fn_message_cmnd:
			.asciiz	"dbaserr -q 0,    /a/dbase.msg"

		default_err_msg:
			.asciiz	"***ERROR xxx ***"
.popseg

