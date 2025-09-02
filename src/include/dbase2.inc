;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export months
.export days

.export opt_on_off
;.export set_opt
.export opt_to
;.export opt_date_fmt
.export opt_display


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
			string80	"TEXT"			; test... endtext
			string80	"CANCEL"
			string80	"QUIT"			; exit (ajouter paramètre <n>)
			string80	"SET"
			string80	"WAIT"			; getkey / pause
			string80	"ACCEPT"		; input
			string80	"INPUT"
			string80	"CLEAR"			; cls
;			string80	"BCD"			; TEST
;			string80	"PARAM"			; TEST
			string80	"STORE"
			string80	"DISPLAY"
			string80	"?"			; echo
;				TOKEN_PRINT = 12-2
			string80	"??"			; echo -n
;				TOKEN_PRINT_NOCR = 13-2

			string80	"RESTORE"		; restore from
			string80	"SAVE"			; save to

			string80	"IIF"			; iif
			string80	"IF"			; if
			string80	"ELSE"
			string80	"ENDIF"

			string80	"SET-DATE"
			string80	"RUN"
			string80	"!"			; Alias de run

			string80	"@"			; @

			string80	"NOTE"			; rem [* ...]

			string80	"PROCEDURE"
;				TOKEN_PROCEDURE = 23
			string80	"DUMP"			; TEST

			string80	"PARAMETERS"

			; [ Spécifique submit
			string80	"GOTO"			; goto
			string80	"CALL"			; call
			string80	"RETURN"		; return
			; ]
								; cd
								; choice

			string80	"DO"			; chain

			string80	"DIR"
			string80	"TYPE"
			string80	"MODIFY"
			string80	"RELEASE"

			string80	"ON"

			; Extensions dBase
			string80	"USE"

			.byte	$00

		.out .sprintf("\t*** cmnd_table: %d", *-cmnd_table)

		; Règle de chaque instruction (dans l'ordre de cmnd_table)
		yacc_tbl:
			.word	RULE_TEXT
			.word	RULE_CANCEL
			.word	RULE_QUIT
			.word	RULE_SET
			.word	RULE_WAIT
			.word	RULE_ACCEPT
			.word	RULE_INPUT
			.word	RULE_CLEAR
;			.word	RULE_BCD
;			.word	RULE_PARAM
			.word	RULE_STORE
			.word	RULE_DISPLAY
			.word	RULE_PRINT
			.word	RULE_PRINT
			.word	RULE_RESTORE
			.word	RULE_SAVE
			.word	RULE_IIF
			.word	RULE_IF
			.word	RULE_ELSE
			.word	RULE_ENDIF
			.word	RULE_SET_DATE
			.word	RULE_RUN
			.word	RULE_RUN
			.word	RULE_AT
			.word	RULE_NOTE
			.word	RULE_PROCEDURE
			.word	RULE_DUMP
			.word	RULE_PARAMETERS

			.word	RULE_GOTO
			.word	RULE_CALL
			.word	RULE_RETURN

			.word	RULE_DO

			.word	RULE_DIR
			.word	RULE_TYPE
			.word	RULE_MODIFY
			.word	RULE_RELEASE

			.word	RULE_ON

			; Extensions dBase
			.word	RULE_USE

		; Liste des cibles possibles des règles (dernier octet d'une règle)
		cmnd_addr:
			.addr	cmnd_text
			.addr	cmnd_cancel
			.addr	cmnd_quit
			.addr	cmnd_set
			.addr	cmnd_wait
			.addr	cmnd_accept
			.addr	cmnd_input
			.addr	cmnd_clear
;			.addr	cmnd_bcd
;			.addr	cmnd_param
			.addr	cmnd_store
			.addr	cmnd_display
			.addr	cmnd_print
			.addr	cmnd_restore
			.addr	cmnd_save
			.addr	cmnd_iif
			.addr	cmnd_if
			.addr	cmnd_else
			.addr	cmnd_endif
			.addr	cmnd_set_date
			.addr	cmnd_run
			;.addr	cmnd_run			; !
			.addr	cmnd_at
			.addr	cmnd_procedure
			.addr	cmnd_dump
			.addr	cmnd_parameters

			.addr	cmnd_goto
			.addr	cmnd_call
			.addr	cmnd_return

			.addr	cmnd_do

			.addr	cmnd_dir
			.addr	cmnd_type
			.addr	cmnd_modify
			.addr	cmnd_release

			.addr	cmnd_on

			; Extensions dBase
			.addr	cmnd_use

		; Commandes dans l'ordre de cmnd_addr
		.enum CMND
			TEXT
			CANCEL
			QUIT
			SET
			WAIT
			ACCEPT
			INPUT
			CLEAR
;			BCD
;			PARAM
			STORE
			DISPLAY
			PRINT
			RESTORE
			SAVE
			IIF
			IF
			ELSE
			ENDIF
			SET_DATE
			RUN
			; RUN					; !
			AT
			PROCEDURE
			DUMP
			PARAMETERS

			GOTO
			CALL
			RETURN

			DO

			DIR
			TYPE
			MODIFY
			RELEASE

			ON

			; Extensions dBase
			USE

			NOOP =$ff
		.endenum


		; Règles syntaxiques
		syn_tbl:
			; On peut fusionner les 3 règles suivantes, dans ce cas
			; CMND:XXX peut faire la différence entre les 2 instructions
			; en regardant cmnd_number
			RULE_TEXT:
				.byte	EOL, CMND::TEXT

			RULE_CANCEL:
				.byte	EOL, CMND::CANCEL

			RULE_QUIT:
				.byte	EOL, CMND::QUIT


			RULE_SET:
				;.byte	OPT, ON_OFF, EOL, CMND::SET
				.byte	OPT, <set_opt, >set_opt, ON_OFF, EOL, CMND::SET

			RULE_WAIT:
				.byte	STRINGZ, TO_IDENTZ, EOL, CMND::WAIT


			; On peut fusionner les 2 règles suivantes, dans ce cas
			; CMND:XXX peut faire la différence entre les 2 instructions
			; en regardant cmnd_number
			RULE_ACCEPT:
				.byte	STRINGZ, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::ACCEPT

			RULE_INPUT:
				.byte	STRINGZ, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::INPUT


			RULE_CLEAR:
				;.byte	EOL, CMND::CLEAR
				.byte	OPTZ, <opt_clear, >opt_clear, EOL, CMND::CLEAR

;			RULE_BCD:
;				.byte	INT, EOL, CMND::BCD
;
;			RULE_PARAM:
;				; .byte	PARAM, EOL, CMND::PARAM
;				.byte	EXPR, EOL, CMND::PARAM


			RULE_STORE:
				; .byte	EXPR, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::STORE
				.byte	TERM, LITERAL, "T",'O'+$80, IDENT, EOL, CMND::STORE

			RULE_DISPLAY:
				.byte	IDENT, EOL, CMND::DISPLAY


			RULE_PRINT:
				; .byte	EXPR, EOL, CMND::PRINT
				; .byte	TERM, EOL, CMND::PRINT
				.byte	TO_EOL, EOL, CMND::PRINT

			RULE_RESTORE:
				.byte	LITERAL, "FRO",'M'+$80, FILENAME, OPTZ, <opt_restore, >opt_restore, EOL, CMND::RESTORE

			RULE_SAVE:
				.byte	LITERAL, "T",'O'+$80, FILENAME, OPTZ, <opt_filter, >opt_filter, TO_EOL, EOL, CMND::SAVE


			RULE_IIF:
				; Modifier la règle: EXPR_L, EOI, CMND::IF
				; Version submit
				; .byte	EXPR1, CMP_OP, EXPR, EOI, CMND::IIF
				.byte EXPR_L, EOI, CMND::IIF

			RULE_IF:
				; Modifier la règle: EXPR_L, EOI, CMND::IF
				; Version dBase
				;.byte	EXPR1, CMP_OP, EXPR, EOL, CMND::IF
				.byte EXPR_L, EOL, CMND::IF

			RULE_ELSE:
				.byte	TO_EOL, EOL, CMND::ELSE

			RULE_ENDIF:
				.byte	TO_EOL, EOL, CMND::ENDIF

			RULE_SET_DATE:
				; .byte	DATE_FMT, EOL, CMND::SET_DATE
				.byte	OPT, <opt_date_fmt, >opt_date_fmt, EOL, CMND::SET_DATE

			RULE_RUN:
				;.byte	STRING, EOL, CMND::RUN
				.byte	TO_EOL, EOL, CMND::RUN

			RULE_AT:
				; Compatibilité submit
				.byte	EXPR_N1, ','+$80, EXPR_N, EOI, CMND::AT
				;.byte	EXPR_N1, ','+$80, EXPR_N, EOL, CMND::AT

			RULE_NOTE:
				.byte	STRING, EOL, CMND::NOOP

			RULE_PROCEDURE:
				.byte	IDENT, EOL, CMND::PROCEDURE

			RULE_DUMP:
				.byte	EOL, CMND::DUMP

			RULE_PARAMETERS:
				; Si on veut que la commande soit directement exécutée
				; .byte	VARGS, EOL, CMND::NOOP
				; Si on veut que cmnd_parameters puisse vérifier qu'on est
				; bien dans une prcoédure
				.byte	TO_EOL, EOL, CMND::PARAMETERS

			RULE_GOTO:
				.byte	IDENT, EOL, CMND::GOTO

			RULE_CALL:
				.byte	IDENT, EOL, CMND::CALL

			RULE_RETURN:
				.byte	EOL, CMND::RETURN

			RULE_DO:
				; .byte	FILENAME, LITERAL, "WIT", 'H'+$80, TO_EOL, EOL, CMND::DO
				.byte	FILENAME, OPTZ, <opt_do, >opt_do, TO_EOL, EOL, CMND::DO

			RULE_DIR:
				.byte	FILENAMEZ, EOL, CMND::DIR

			RULE_TYPE:
				.byte	FILENAME, EOL, CMND::TYPE

			RULE_MODIFY:
				.byte	OPT, <opt_modify, >opt_modify, FILENAME,EOL, CMND::MODIFY

			RULE_RELEASE:
				.byte	IDENT, EOL, CMND::RELEASE

			RULE_ON:
				.byte	OPT, <opt_on, >opt_on, TO_EOL, EOL, CMND::ON

			; Extensions dBase
			RULE_USE:
				.byte	FILENAMEZ, EOL, CMND::USE

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
			string80	"UPPER("		; !() en dBase II
			string80	"LOWER("
			string80	"ISUPPER("
			string80	"ISLOWER("
			string80	"FILE("
			string80	"GETENV("		; pwd [getenv("PATH")]

			string80	"ASC("

			; Argument expression
			string80	"TYPE("
				; TOKEN_TYPE=22			; Défini dans dbase.inc
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
			string80	"SUBSTR("		; $() en dBase II

			; Arguments: numérique, numérique
			string80	"MAX("
			string80	"MIN("

			string80	"SPEEK("		; Supplément perso

			; Arguments: chaine, numérique, numérique, chaine
			string80	"STUFF("

			.byte	$00

		.out .sprintf("\t*** func_table: %d", *-func_table)
		.if ::LOOKUP_TABLE_PAGE
			; [ Si les tables sont limitées à 256 caractères maxy
			.assert *-func_table < $100, error , "Table too large"
			; ]
		.endif

		func_addr:
			; Argument numérique
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

			; Argument chaine
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

			; Argument expression
			.word	fn_type
			.word	fn_isalpha

			; Arguments: chaine, numérique
			.word	fn_left
			.word	fn_right
			.word	fn_replicate

			; Aucun argument
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

			; Argument date
			.word	fn_dtoc
			.word	fn_day
			.word	fn_month
			.word	fn_year
			.word	fn_dow
			.word	fn_cmonth
			.word	fn_cdow

			; Arguments: chaine, chaine
			.word	fn_at

			; Arguments: chaine, numérique, numérique
			.word	fn_substr

			; Arguments: numérique, numérique
			.word	fn_max
			.word	fn_min

			.word	fn_peek_str

			; Arguments: chaine, numérique, numérique, chaine
			.word	fn_stuff

		func_yacc_tbl:
			; Argument numérique
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

			; Argument chaine
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

			; Argument expression
			.word	RULE_FN_X
			.word	RULE_FN_X

			; Arguments: chaine, numérique
			.word	RULE_FN_CN
			.word	RULE_FN_CN
			.word	RULE_FN_CN

			; Aucun argument
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

			; Argument date
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT
			.word	RULE_FN_DT

			; Arguments: chaine, chaine
			.word	RULE_FN_CC

			; Arguments: chaine, numérique, numérique
			.word	RULE_FN_CNN

			; Arguments: numérique, numérique
			.word	RULE_FN_NN
			.word	RULE_FN_NN

			.word	RULE_FN_NN

			; Arguments: chaine, numérique, numérique, chaine
			.word	RULE_FN_CNNC

		func_syn_tbl:
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

		; --------------------------------------------------------------
		;			SET xxx
		; --------------------------------------------------------------
		set_opt:
			string80	"ALTERNATE"	; on/OFF  |  TO [<fichier>] | on/OFF
			string80	"BELL"		; ON/off
			string80	"CARRY"		; on/OFF
			; string80	"CATALOG"	; on/OFF  |  TO [<filename>/?]  |  on/OFF
			string80	"COLON"		; ON/off  (dBase II only)
			string80	"CONFIRM"	; on/OFF
			string80	"CONSOLE"	; ON/off
			string80	"DEBUG"		; on/OFF
			string80	"DELETE"	; on/OFF   (dBase III affiche DELETED)
			; string80	"DELIMTERS"	; on/OFF  |  TO [<expC>]/DEFAULT
			; string80	"DEVICE"	; TO SCREEN/print
			string80	"ECHO"
			string80	"EJECT"		; dBase II only
			; string80	"ENCRYPT"	; ON/off (non affiché par DISPLAY STATUS)
			string80	"ESCAPE"	; ON/off
			string80	"EXACT"		; on/OFF
			; string80	"FIELDS"	; on/OFF  |  TO [<field list>/ALL]
			; string80	"FIXED"		; on/OFF
			; string80	"HEADING"	; ON/off  | TO <expC> (dBase II uniquement?)
			; string80	"HELP"		; ON/off
			; string80	"HISTORY"	; ON/off  |  TO <expN>
			string80	"INTENSITY"	; ON/off
			; string80	"MENUS"		; ON/off
			string80	"LINKAGE"	; OFF/on  (dBase II only)
			string80	"PRINT"		; on/OFF  |  TO [LPT1/LPT2/LPT3] / [COM1/COM2] / [\\<computer>\<device>=LPTx] (TO xxx => extension dBase III)
			; string80	"STATUS"	; ON/off dBase III
			string80	"RAW"		; OFF/on  (dBase II only)
			string80	"SPACE"		; dBase II only
			string80	"STEP"		; on/OFF
			string80	"TALK"		; ON/off
			; string80	"TITLE"		; ON/off

			; dBase II: non affichés par DISPLAY STATUS
			; dBase III: affichés
			string80	"DELETED"	; alias de DELETE
			string80	"DOHISTORY"	; on/OFF
			string80	"SAFETY"	; ON/off
			string80	"SCOREBOARD"	; ON/off
			string80	"UNIQUE"	; on/OFF

			string80	"CENTURY"	; on/OFF
			OPT_CENTURY = 24

			; [ Ajout
			string80	"CURSOR"	; ON/off
			OPT_CURSOR = 25
			; ]

			; dBase ??? (> III+)
			; remplace le caractère de séparation de la date par le premier caracère de la chaine, si pas de chaine => revient à celui par défaut du format)
			; string80	"MARK"		; TO [ / "x"]
			.byte	$00

		opt_on_off:
			string80	"OFF"
			string80	"ON"
			.byte	$00

		opt_to:
			string80	"TO"
			.byte	$00

		opt_date_fmt:
			string80	"AMERICAN"	; = mm/jj/aa
			string80	"ANSI"		; = aa.mm.jj
			string80	"BRITISH"	; = jj/mm/aa
			string80	"FRENCH"	; = jj/mm/aa
			string80	"GERMAN"	; = jj.mm/aa
			string80	"ITALIAN"	; = jj-mm-aa

			; dBase ??? (> III+)
			; string80	"JAPAN"		; = aa/mm/jj
			; string80	"USA"		; = mm-jj-aa
			; string80	"MDY"		; = mm/jj/aa
			; string80	"DMY"		; = jj/mm/aa
			; string80	"YMD"		; = aa/mm/jj

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

		; --------------------------------------------------------------
		;			DO
		; --------------------------------------------------------------
		opt_do:
			string80	"WITH"
			.byte	$00

		; --------------------------------------------------------------
		;			RESTORE
		; --------------------------------------------------------------
		opt_restore:
			string80	"ADDITIVE"
			.byte	$00

		; --------------------------------------------------------------
		;			MODIFY
		; --------------------------------------------------------------
		opt_modify:
			string80	"COMMAND"
			string80	"FILE"
			.byte	$00

		; --------------------------------------------------------------
		;			FILTER
		; --------------------------------------------------------------
		opt_filter:
			string80	"ALL LIKE"
			string80	"ALL EXCEPT"
			.byte	$00

		; --------------------------------------------------------------
		;			ON
		; --------------------------------------------------------------
		opt_on:
			string80	"KEY"
			string80	"ERROR"
			string80	"ESCAPE"
			.byte	$00

		; --------------------------------------------------------------
		;		Opérateurs de comparaison
		; --------------------------------------------------------------
		cmp_oper:
			string80	"<"
			string80	">"
			string80	"<>"
			;string80	"!="
			;string80	"/="
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


.if 0
string80	"APPEND"
string80	"BROWSE"
string80	"CHANGE"
	string80	"CLEAR"
string80	"CONTINUE"
string80	"COPY"
string80	"COUNT"
string80	"CREATE"
string80	"DELETE"
	string80	"DISPLAY"
string80	"EDIT"
string80	"ERASE"
string80	"FIND"
string80	"GOTO"
string80	"GO"
string80	"INDEX"
string80	"INSERT"
string80	"JOIN"
string80	"LIST"
string80	"LOCATE"
string80	"MODIFY"
string80	"PACK"
	string80	"QUIT"
string80	"RECALL"
string80	"RELEASE"
string80	"RENAME"
string80	"REPLACE"
string80	"REPORT"
	string80	"RESTORE"
	string80	"SAVE"
string80	"SELECT"
	string80	"SET"
string80	"SORT"
string80	"SKIP"
	string80	"STORE"
string80	"SUM"
	string80	"TEXT"
string80	"TOTAL"
string80	"UPDATE"
string80	"USE"

	string80	"ACCEPT"
string80	"CALL"
	string80	"INPUT"
	string80	"WAIT"
string80	"AVERAGE"

; Options
string80	"ADDITIVE"
string80	"ALL"
string80	"BEFORE"
string80	"BLANK"
string80	"BOTTOM"
string80	"DELIMITED"
string80	"FIELD"
string80	"FILE"
string80	"FILES"
string80	"FOR"
string80	"FROM"
string80	"GETS"
string80	"LIKE"
string80	"MEMORY"
string80	"NEXT"
string80	"OFF"
string80	"ON"
string80	"PICTURE"
string80	"PLAIN"
string80	"PRIMARY"
string80	"PRINT"
string80	"RECORD"
string80	"REST"
string80	"SDF"
string80	"SECONDARY"
string80	"STATUS"
string80	"STRUCTURE"
string80	"TYPEAHEAD"
string80	"TO"
string80	"TOP"
string80	"USING"
string80	"WITH"

; SET xxx ON|OFF
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

; SET xxx TO
string80	"ALTERNATE"
string80	"COLOR"
string80	"DATE"
string80	"DEFAULT"
string80	"DEVICE"
string80	"ESCAPE"
string80	"FORMAT"
string80	"FUNCTION"
string80	"HISTORY"
string80	"TYPEAHEAD"

; SET DATE TO xxx
string80	"AMERICAN"
string80	"ANSI"
string80	"BRITISH"
string80	"FRENCH"
string80	"GERMAN"
string80	"ITALIAN"

string80	".AND."
string80	".NOT."
string80	".OR."
	string80	"CHR("
	string80	"DATE()"
string80	"EOF"
	string80	"FILE("
string80	"INT("
	string80	"LEN("
string80	"PEEK("
	string80	"STR("
string80	"TEST("
	string80	"TRIM("
	string80	"TYPE("
	string80	"VAL("


; dBase II, par ordre des tokens
string80	"IF"
string80	"ELSE"
string80	"ENDIF"
string80	"DO"
string80	"ENDDO"
string80	"CASE"
string80	"OTHERWISE"
string80	"ENDCASE"
string80	"DO WHILE"
string80	"DO CASE"
string80	"?"
string80	"RELEASE"
string80	"RETURN"
string80	"SELECT"

string80	"@"
string80	"ACCEPT"
string80	"APPEND"
string80	"BROWSE"
string80	"CALL"
string80	"CANCEL"
string80	"CHANGE"
string80	"CLEAR"
string80	"CPOY"
string80	"COUNT"
string80	"CREATE"
string80	"DELETE"
string80	"CONTINUE"
string80	"EDIT"
string80	"EJECT"
string80	"ERASE"
string80	"GOTO"
string80	"FIND"
string80	"HELP"
string80	"INDEX"
string80	"INPUT"
string80	"INSERT"
string80	"JOIN"
string80	"LIST"
string80	"LOAD"
string80	"LOCATE"
string80	"LOOP"
string80	"MODIFY"
string80	"PACK"
string80	"POKE"
string80	"QUIT"
string80	"READ"
string80	"RECALL"
string80	"REINDEX"
string80	"REMARK"
string80	"RENAME"
string80	"REPLACE"
string80	"REPORT"
string80	"RESET"
string80	"RESTORE"
string80	"SAVE"
string80	"SET"
string80	"SKIP"
string80	"SORT"
string80	"SUM"
string80	"TEXT"
string80	"TOTAL"
string80	"UNLOCK"
string80	"UPDATE"
string80	"USE"
string80	"WAIT"
.endif

