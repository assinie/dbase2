
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
.import readline

.importzp line_ptr

.import submit_line

.import string
.import ident
.import param_type

.import cmnd_store
.import get_expr
.import get_string

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_accept

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		; unsigned short ptr

	.segment "DATA"
		; unsigned char ident_save[IDENT_LEN+1]
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
.proc cmnd_accept
		lda	string
		beq	accept

	disp_string:
		print	string


	accept:
		input	":", ::LINE_MAX_SIZE, line_ptr

		crlf

		; Copie de la chaine
		ldy	#$ff
	loop1:
		iny
		lda	(line_ptr),y
		sta	string,y
		bne	loop1

		lda	#'C'
		sta	param_type
		jmp	cmnd_store
.endproc

