
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
.include "macros/utils.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp pfac
.import ident
.import param_type

.import cmnd_store
.import set_bytevar

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_getkey
.export set_keyvar

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
		key_var:
			.asciiz "KEY"

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
.proc cmnd_getkey
		; Vide le buffer clavier
                ldx     #$00
                .byte	$00, XVIDBU
		asl	KBDCTC

		; Initialise key
		lda	#$00
		sta	pfac

		cgetc
		asl	KBDCTC
		bcs	break

		; sta	key

	break:
		; clc
		; rts
		; jmp	set_keyvar
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	A: code erreur
;
; Sortie:
;	cf cmnd_store
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.if 1
.proc set_keyvar
		ldx	#<key_var
		ldy	#>key_var
		jmp	set_bytevar
.endproc

.else
.proc set_keyvar
		; Place le code erreur dans pfac
		sta	pfac
		lda	#$00
		sta	pfac+1
		sta	pfac+2
		sta	pfac+3

		; Initialise pfac (errorlevel < 256)

		; Variable errorlevel
		ldx	#$ff
	loop1:
		inx
		lda	key_var,x
		sta	ident,x
		bne	loop1

	loop2:
		inx
		cpx	#IDENT_LEN
		bcs	end
		sta	ident,x
		bcc	loop2

	end:
		; Variable de type numérique
		lda	#'N'
		sta	param_type

		; Mise à jour de la variable
		jmp	cmnd_store
.endproc
.endif
