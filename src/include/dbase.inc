
;----------------------------------------------------------------------
;- = 45	($2d)
;. = 46	($2e)
;/ = 47	($2f)

;AMERICAN	; = mm/jj/aa	=> format 0 (offset mm/jj =2)
;ANSI		; = aa.mm.jj	=> format 1 (offset aa.mm.jj = 1)
;
;BRITISH	; = jj/mm/aa	=> format 2 (offset jj/mm = 3)
;FRENCH		; = jj/mm/aa
;GERMAN		; = jj.mm/aa
;ITALIAN	; = jj-mm-aa
;
;
;Codage format date:
;	f f  s c s s s s	=> ff: format, c: century, ss: séparateur
;
;AMERICAM	=> $2f + $00
;ANSI		=> $2e + $40
;BRITISH/FRENCH	=> $2f + $80
;GERMAN		=> $2e + $80
;ITALIAN	=> $2d + $80
;
;	lda	date_fmt
;	and	#$2f
;	sta	sep
;	lda	#$10
;	bit	date_fmt
;	beq	century_off
;	bne	century_on
;	bmi	BRITISH/FRENCH/GERMAN/ITALIAN
;	bvs	ANSI
;	bvc	AMERICAN
;----------------------------------------------------------------------



.ifndef DBASE_INC
; SUBMIT = 1
HAS_ON_ERROR = 1

	; --------------------------------------------------------------
	;			Pour l'horloge DS 1501
	; --------------------------------------------------------------
	DS1501_SECONDS_REGISTER = $0360
	DS1501_MINUTES_REGISTER = $0361
	DS1501_HOUR_REGISTER    = $0362
	DS1501_DAY_REGISTER     = $0363
	DS1501_DATE_REGISTER    = $0364
	DS1501_MONTH_REGISTER   = $0365
	DS1501_YEAR_REGISTER    = $0366
	DS1501_CENTURY_REGISTER = $0367


	; --------------------------------------------------------------
	;		Structure pour les variables
	; --------------------------------------------------------------
	IDENT_LEN = 10
	VALUE_LEN = 10

	typedef .struct st_entry
		unsigned char name[10+1]
		unsigned char type		; 'C', 'N', 'L', 'D'
		unsigned char len
		unsigned short data_ptr
		.ifdef USE_LINKEDLIST
			unsigned short _next_ptr
			unsigned char _occupied
		.endif
	.endstruct

	ST_ENTRYLEN = .sizeof(st_entry)

	.ifdef USE_LINKEDLIST
		ENTRY_LEN = ST_ENTRYLEN - 3
	.else
		ENTRY_LEN = ST_ENTRYLEN
	.endif

	; --------------------------------------------------------------
	;		Nombre maximal de variables
	; --------------------------------------------------------------
	VARS_MAX = 256/ST_ENTRYLEN
	VARS_DATALEN = 32

	.out .sprintf("256/ST_ENTRYLEN = %d", VARS_MAX)

	; --------------------------------------------------------------
	;			Opérateurs de comparaison
	; --------------------------------------------------------------
	OP_LT = 1	; "<"
	OP_GT = 2	; ">"
	OP_NE = 3	; "<>"
	OP_EQ = 4	; "="
	OP_LE = 5	; "<="
	OP_GE = 6	; ">="


	; --------------------------------------------------------------
	;				Préfixes
	; --------------------------------------------------------------
	.ifndef SUBMIT
		PARAM_PREFIX = '&'
		CTRL_PREFIX = '^'
	.else
		PARAM_PREFIX = '$'
		CTRL_PREFIX = '^'
	.endif

	; --------------------------------------------------------------
	;			Gestion des labels
	; --------------------------------------------------------------
	CASE_SENSITIVE_LABELS .set 0
	MAX_LABELS = 20
	LABEL_TABLE_SIZE = 128

	.out .sprintf("Labels max: %d", MAX_LABELS)

	; --------------------------------------------------------------
	;				Divers
	; --------------------------------------------------------------
	FILENAME_LEN = 30

	; Pour find_cmnd
	CASE_SENSITIVE_LABELS .set 0
	; de main.s
	; LINE_MAX_SIZE = 64
	LINE_MAX_SIZE = 128

	HISTORY_SIZE = 5

	; 0: pas de limite de taille
	; 1: limite à 256 caractères maxi
	LOOKUP_TABLE_PAGE = 0

;	SUBMIT_LINE_MAX_SIZE = 200

	.ifndef SUBMIT
	; [ dBase
		.define PROMPT "dBase II>"
		; REM_CHR = '*'
		REM_CHR = ';'

		EXT_STRERR = 1

		TOKEN_PRINT = 10
		TOKEN_PRINT_NOCR = 11

		TOKEN_TYPE = 22

		TOKEN_PROCEDURE = 23

		; [ Pour tests
		LABEL_CHR = ':'
		; ]

		; Ajout perso
		TOKEN_PEEK = 8

		DEBUG = 1
	; ]
	.else
	; [ submit
		.define PROMPT "submit>"
		REM_CHR = ';'
		LABEL_CHR = ':'

		EXT_STRERR = 0

		TOKEN_PRINT = 6
		TOKEN_PRINT_NOCR = 5

		; Ajout perso
		; Pas utilisé pour submit mais nécessaire pour la compilation
		; de fn_peek.s
		; /!\ À ajuster si peek/deek sont utilisés par submit
		TOKEN_PEEK = 8
	; ]
	.endif

	; --------------------------------------------------------------
	;
	; --------------------------------------------------------------
	INIFILE_INC = 1
.endif
