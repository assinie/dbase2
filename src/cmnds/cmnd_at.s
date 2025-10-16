
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
.import param1
.importzp pfac1
.importzp pfac

; Pour compatibilité sbumit
.import cmnd_print
;.import get_expr_str
.import get_term_str
.importzp line_ptr

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_at

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
; TOKEN_PRINT_NOCR = 13-2

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

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
; dBase: @ l,c : efface la ligne 'l' à partir de la colonne 'c'
; dBase: ligne <= 24 (lignes 22-24 utilisées par le statut, écrasées
;         par un SET MESSAGE ou un message d'aide)
;----------------------------------------------------------------------
.proc cmnd_at
		; Vérifie que LINE < 256
		lda	pfac1+1
		ora	pfac1+2
		ora	pfac1+3
		bne	error30

		; Vérifie que COL < 256
		lda	pfac+1
		ora	pfac+2
		ora	pfac+3
		bne	error30

		; Line < 28?
		lda	pfac1
		cmp	#28
		bcs	error30

		; COL < 40?
		lda	pfac
		cmp	#$40
		bcs	error30

		; /!\ Suppose que Y est préservé par cputc
		cputc   $1f
		lda     pfac1
		adc	#$40
		cputc
		lda     pfac
		adc	#$40
		cputc

		; [ Compatibilité submit
		lda	(line_ptr),y
		beq	end

		; On peut avoir un echo [-n] <string>
		; (Pour dBASE on peut avoir GET, SAY, TO, CLEAR,
		;  il faudra utiliser find_cmnd)
		; [ Si la définition de PRINT est : .byte TERM, EOL, CMND::PRINT
		; sec
		; lda	line_ptr
		; ldx	line_ptr+1
		; jsr	get_term_str
		; bcs	error45
		; jmp	cmnd_print
		; ]
		; [ Sinon
		tya
		tax
		lda	#TOKEN_PRINT_NOCR
		jmp	cmnd_print
		; ]
;	error45:
;		lda	#45
;		rts
		; ]

	end:
		clc
		rts

	error30:
		; 30 Position is off the screen.
		lda	#30
		sec
		rts
.endproc


