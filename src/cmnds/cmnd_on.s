
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
.importzp line_ptr

.import skip_spaces

; From get_tokens
.import opt_num

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_on
.export on_error

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

	.segment "DATA"
		on_key:
			.res	LINE_MAX_SIZE,0

		on_error:
			.res	LINE_MAX_SIZE,0

		on_escape:
			.res	LINE_MAX_SIZE,0

		on_ptrs:
			.word	on_key, on_error, on_escape
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
.proc cmnd_on
		; Récupère l'adresse de la chaîne correspondant à l'option
		lda	opt_num
		asl
		tay
		lda	on_ptrs,y
		sta	stxx+1
		lda	on_ptrs+1,y
		sta	stxx+2

		; Transfère l'offset vers le paramètre dans Y
		; et saute les évzntuels espaces
		txa
		tay
		lda	line_ptr
		ldx	line_ptr+1
		jsr	skip_spaces

		dey
		ldx	#$ff
	loop:
		iny
		inx
		lda	(line_ptr),y
	stxx:
		sta	on_error,x
		bne	loop

	end:
		clc
		rts
.endproc


