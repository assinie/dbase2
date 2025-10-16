
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
.import string

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export pattern_filter

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
;	C: 0 -> Ok, 1 -> Ko
;	A,X,Y: Modifiés
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		param1 (pattern)
;		string
; Sous-routines:
;	-
;----------------------------------------------------------------------
; http://6502.org/source/strings/patmatch.htm
;
; Input:  A NUL-terminated, <255-length pattern at address PATTERN.
;         A NUL-terminated, <255-length string pointed to by STR.
;
; Output: Carry bit = 1 if the string matches the pattern, = 0 if not.
;
; Notes:  Clobbers A, X, Y. Each * in the pattern uses 4 bytes of stack.
;

; MATCH1  = '?'		; Matches exactly 1 character
; MATCHN  = '*'		; Matches any string (including "")
; PATTERN = $2000	; Address of pattern
; STR     = $6		; Pointer to string to match

.proc pattern_filter
		ldx	#$00			; X is an index in the pattern
		ldy	#$FF			; Y is an index in the string
	next:
		lda	param1,x		; Look at next pattern character
		cmp	#'*'			; Is it a star?
		beq	star			; Yes, do the complicated stuff

		iny				; No, let's look at the string
		cmp	#'?'			; Is the pattern caracter a ques?
		bne	reg			; No, it's a regular character

		; lda	(STR),y			; Yes, so it will match anything
		lda	string,y		; Yes, so it will match anything
		beq	fail			;  except the end of string

	reg:
		; cmp	(STR),y			; Are both characters the same?
		cmp	string,y		; Are both characters the same?
		bne	fail			; No, so no match

		inx				; Yes, keep checking
		cmp	#0			; Are we at end of string?
		bne	next			; Not yet, loop

	found:
		rts				; Success, return with C=1

	star:
		inx				; Skip star in pattern
		cmp	param1,x		; String of stars equals one star
		beq	star			;  so skip them also

	stloop:
		txa				; We first try to match with * = ""
		pha				;  and grow it by 1 character every
		tya				;  time we loop
		pha				; Save X and Y on stack
		jsr	next			; Recursive call
		pla				; Restore X and Y
		tay
		pla
		tax
		bcs	found			; We found a match, return with C=1

		iny				; No match yet, try to grow * string
		; lda	(STR),y			; Are we at the end of string?
		lda	string,y		; Are we at the end of string?
		bne	stloop			; Not yet, add a character

	fail:
		clc				; Yes, no match found, return with C=0
		rts

.endproc


