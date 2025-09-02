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
.include "macros/utils.mac"
.include "include/dbase.inc"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
	; --------------------------------------------------------------
	;			Fonctions LEX
	; --------------------------------------------------------------
.import skip_spaces
.import get_ident
.import get_word
.import get_string
.import get_int
.import get_on_off
.import get_opt
.import get_optz
.import get_string_opt
.import get_to_ident_opt
.import get_literal
.import get_param
.import get_ident_opt
.import get_param_num
.import get_param_str
.import get_expr
.import get_expr1
.import get_expr_num
.import get_expr_num1
.import get_expr_num_opt
.import get_expr_str
.import get_expr_str1
.import get_expr_logic
.import get_term
.import get_term_num
.import get_term_str
.import get_expr_date
.import get_filename
.import get_filenamez
.import get_cmp_op
;.import get_date_fmt
.import get_line
.import get_vargs

; Commandes
.import cmnd_text
.import cmnd_cancel
.import cmnd_quit
.import cmnd_set
.import cmnd_wait
.import cmnd_accept
.import cmnd_input
.import cmnd_clear
.import cmnd_bcd				; TEMPORAIRE
.import cmnd_param				; TEMPORAIRE
.import cmnd_store
.import cmnd_display
.import cmnd_print
.import cmnd_restore
.import cmnd_save
.import cmnd_iif
.import cmnd_if
.import cmnd_else
.import cmnd_endif
.import cmnd_set_date
.import cmnd_run
.import cmnd_at
.import cmnd_dump
.import cmnd_call
.import cmnd_return
.import cmnd_exec				; SUBMIT

.import cmnd_getkey				; Ajout pour submit

.import fn_chr
.import fn_int
.import fn_space
.import fn_len
.import fn_str
.import fn_hex					; Ajout
.import fn_oct					; Ajout
.import fn_bin					; Ajout
.import fn_trim
.import fn_ltrim
.import fn_rtrim
.import fn_val
.import fn_upper
.import fn_lower
.import fn_isupper
.import fn_islower
.import fn_file
.import fn_asc
.import fn_at
.import fn_sgn					; Ajout

.import fn_type

.import fn_isalpha
.import fn_left
.import fn_right
.import fn_substr
.import fn_replicate

.import fn_row
.import fn_col
.import fn_diskspace
.import fn_error
.import fn_getenv
.import fn_message
.import fn_os
.import fn_time
.import fn_version

.import fn_date

.import fn_dtoc
.import	fn_day
.import fn_month
.import fn_year
.import fn_dow
.import fn_cmonth
.import fn_cdow

.import fn_peek_str				; Ajout
.import fn_peek					; Ajout

	; --------------------------------------------------------------
	;			Commandes essentielles
	; --------------------------------------------------------------
.import cmnd_print				; ?
.import cmnd_append
.import cmnd_average
.import cmnd_browse
.import cmnd_change
.import cmnd_clear				; CLEAR [MEMORY]
.import cmnd_continue
.import cmnd_copy
.import cmnd_count
.import cmnd_create
.import cmnd_delete
.import cmnd_delete_file
.import cmnd_dir				; Ok
.import cmnd_display				; DISPLAY (<var> | MEMORY)
.import cmnd_do
.import cmnd_edit
.import cmnd_erase
.import cmnd_export
.import cmnd_find
.import cmnd_go
.import cmnd_goto				; (submit)
.import cmnd_import
.import cmnd_index
.import cmnd_label
.import cmnd_list
.import cmnd_locate
.import cmnd_modify				; Ok MODIFY (FILE | COMMAND) <filename>
.import cmnd_pack
.import cmnd_query
.import cmnd_quit				; Ok
.import cmnd_recall
.import cmnd_release				; RELEASE <varmem>
.import cmnd_rename
.import cmnd_replace
.import cmnd_report
.import cmnd_screen
.import cmnd_seek
.import cmnd_set				;
.import cmnd_skip
.import cmnd_sort
.import cmnd_store				; Ok
.import cmnd_sum
.import cmnd_total
.import cmnd_type				; Ok
.import cmnd_use

	; --------------------------------------------------------------
	;			Commandes avancées
	; --------------------------------------------------------------
.import cmnd_at					; @
.import cmnd_accept				; Ok
.import cmnd_cancel				; Ok
.import cmnd_call				; (version submit <=> gosub)
.import cmnd_close
.import cmnd_copy_file
.import cmnd_display_cmds			; DISPLAY ( <var> | MEMORY)
.import cmnd_do_case
.import cmnd_do_while
.import cmnd_eject
.import cmnd_exit				;
.import cmnd_iif				; Partiel IIF <cond> <instruction>
.import cmnd_if					; OK
.import cmnd_else				; OK
.import cmnd_endif				; OK
.import cmnd_input				; Ok
.import cmnd_insert
.import cmnd_join
.import cmnd_load
.import cmnd_list_cmds
.import cmnd_loop
.import cmnd_macro
.import cmnd_modify_cmds			; MODIFY (FILE | COMMAND) <filename>
.import cmnd_note				; Ok
.import cmnd_on
.import cmnd_parameters
.import cmnd_private
.import cmnd_procedure				; Ok
.import cmnd_public
.import cmnd_read
.import cmnd_reindex
.import cmnd_restore				; RESTORE FROM
.import cmnd_resume
.import cmnd_retry
.import cmnd_return				; Ok (version submit)
.import cmnd_run				; Ok
.import cmnd_save				; SAVE TO
.import cmnd_select
.import cmnd_suspend
.import cmnd_text				; Ok
.import cmnd_update
.import cmnd_view
.import cmnd_wait				; Ok
.import cmnd_zap

	; --------------------------------------------------------------
	;			Fonctions chaine
	; --------------------------------------------------------------
.import fn_asc					; Ok
.import fn_at					; Ok
.import fn_chr					; Ok
.import fn_isalpha				; Ok
.import fn_islower				; Ok
.import fn_isupper				; Ok
.import fn_left					; Ok
.import fn_len					; Ok
.import fn_lower				; Ok
.import fn_ltrim				; Ok
.import fn_replicate				; Ok
.import fn_right				; Ok
.import fn_rtrim				; Ok
.import fn_space				; Ok
.import fn_stuff				; Ok
.import fn_substr				; Ok
.import fn_trim					; Ok
.import fn_upper				; Ok

	; --------------------------------------------------------------
	;			Fonctions date
	; --------------------------------------------------------------
.import fn_cdow					; Ok
.import fn_cmonth				; Ok
.import fn_ctod					; Ok
.import fn_date					; Ok
.import fn_day					; Ok
.import fn_dow					; Ok
.import fn_dtoc					; Ok
.import fn_month				; Ok
.import fn_year					; Ok

	; --------------------------------------------------------------
	;			Fonctions environnement
	; --------------------------------------------------------------
.import fn_col					; Ok
.import fn_diskspace				; Ok
.import fn_error				; Ok
.import fn_file					; Ok
.import fn_fklabel
.import fn_fkmax
.import fn_getenv				; Ok
.import fn_inkey				; Ok
.import fn_iscolor
.import fn_message				; Ok
.import fn_os					; Ok
.import fn_pcol
.import fn_prow
.import fn_readkey
.import fn_row					; Ok
.import fn_time					; Ok
.import fn_type					; Ok
.import fn_verion				; Ok

	; --------------------------------------------------------------
	;			Fonctions numériques
	; --------------------------------------------------------------
.import fn_abs
.import fn_exp
.import fn_iif
.import fn_int					;
.import fn_log
.import fn_max					; Ok
.import fn_min					; Ok
.import fn_mod
.import fn_round
.import fn_sgn					; Ok
.import fn_sqrt
.import fn_str					; Ok
.import fn_transform
.import fn_val					; Ok

	; --------------------------------------------------------------
	;		Fonctions de base de données
	; --------------------------------------------------------------
.import fn_bof
.import fn_dbf
.import fn_deleted
.import fn_eof
.import fn_field
.import fn_found
.import fn_lupdate
.import fn_ndx
.import fn_reccount
.import fn_recno
.import fn_recsize

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_table
.export cmnd_addr
.export lex_tbl
.export yacc_tbl

.export func_table
.export func_addr
;.export func_param_count

.export func_yacc_tbl

.export cmp_oper
.export osenv
.export os_default
.export uname
.export fn_message_cmnd
.export default_err_msg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		; --------------------------------------------------------------
		;			Tokens Lexicaux
		; --------------------------------------------------------------
		lex_tbl:
			.addr	get_ident
;			.addr	get_word
			.addr	get_string
;			.addr	get_int
			.addr	get_opt
			.addr	get_optz
		.ifndef SUBMIT
			.addr	get_on_off
		.endif
			.addr	get_string_opt
			.addr	get_to_ident_opt
			.addr	get_literal

;			.addr	get_param
;			.addr	get_ident_opt
;			.addr	get_param_num
;			.addr	get_param_str

			.addr	get_expr
			.addr	get_expr1
			.addr	get_expr_num
			.addr	get_expr_num_opt
			.addr	get_expr_num1

			.addr	get_expr_str
			.addr	get_expr_str1
		.ifndef SUBMIT
			.addr	get_expr_date
		.endif
			.addr	get_expr_logic

			.addr	get_term
;			.addr	get_term_num
;			.addr	get_term_str

			.addr	get_filename
			.addr	get_filenamez
			.addr	get_cmp_op
;			.addr	get_date_fmt
			.addr	get_line
			.addr	get_vargs


		; Symboles dans l'ordre de lex_tbl
		.enum
			IDENT
;			WORD
			STRING
;			INT
			OPT
			OPTZ
		.ifndef SUBMIT
			ON_OFF
		.endif
			STRINGZ
			TO_IDENTZ
			LITERAL

;			PARAM
;			IDENTZ
;			PARAM_N
;			PARAM_S

			EXPR
			EXPR1
			EXPR_N
			EXPR_NZ
			EXPR_N1

			EXPR_C
			EXPR_C1
		.ifndef SUBMIT
			EXPR_D
		.endif

			EXPR_L

			TERM
;			TERM_N
;			TERM_C

			FILENAME
			FILENAMEZ
			CMP_OP
;			DATE_FMT
			TO_EOL
			VARGS

			PGM_ONLY = $fd
			EOI = $fe
			EOL = $ff
		.endenum

.popseg

.ifdef SUBMIT
	.include "include/submit.inc"
.else
	.include "include/dbase2.inc"
.endif

