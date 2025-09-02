
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
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp lex_work_ptr

.import opt_num

.import vars_index
.import vars_data_index
.import vars_datas

.import set_errorlevel

.import tabase

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_clear

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
OPT_ALL = $00
OPT_MEMORY = $03

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short ptr

	.segment "DATA"
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
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc cmnd_clear
		lda	opt_num
		beq	clr_memory

		cmp	#$ff
		bne	memory

		cputc	$0c
		clc
		rts

	memory:
		cmp	#OPT_MEMORY
		bne	end

	clr_memory:
		; Nombre de variables dans la table
		lda	#$00
		sta	vars_index

		;Initialise la table des variables
		ldy	tabase
		sty	ptr
		ldy	tabase+1
		sty	ptr+1

		; /!\ ATTENTION: table de 256 octets uniquement
		ldy	#$00
	loop:
		sta	(ptr),y
		iny
		bne	loop

		; Pointeur vers la table des données
		ldy	#<vars_datas
		sty	vars_data_index
		ldy	#>vars_datas
		sty	vars_data_index+1

		; Initialise errorlevel
		;lda	#$00
		jsr	set_errorlevel

	end:
		clc
		rts
.endproc


