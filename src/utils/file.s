;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"
.include "errno.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"
.include "ch376.inc"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import fgets
.import fseek

.import fp

.import linenum

.import fpos_text
.import buffer_reset

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export open
.export fgetline
.export close
.export fpos

; Pour fgets
.export reopen

;.export stack_ptr
.export empty_stack
.export push
.export pop

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
MAX_LEVELS = 20

typedef .struct stack_item
	unsigned short line
	unsigned long offset
.endstruct

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
		unsigned long fpos

		unsigned short stack_ptr

		; Voir pour utiliser un malloc et un pointeur vers la pile
		struct stack_item, stack[MAX_LEVELS]

		; Pour fgetline
		unsigned char buffer[LINE_MAX_SIZE]

		unsigned short filename

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
;	fgets
;----------------------------------------------------------------------
.proc open
		sta	filename
		sty	filename+1

		fopen (filename), O_RDONLY, , fp
		cmp	#$ff
		bne	end

		cpx	#$ff
		beq	error1

	end:
		; Initialise la position dans le fichier
		lda	#$00
		ldy	#$03
	loop:
		sta	fpos,y
		sta	fpos_text,y
		dey
		bpl	loop

		; Initialise le buffer de lecture
		jsr	buffer_reset

		lda	fp

		clc
		rts

	error1:
		; 1 File does not exist.
		lda	#01
		sec
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: modifié
;	X,Y: inchangés
;
; Variables:
;       Modifiées:
;               fpos
;       Utilisées:
;               -
; Sous-routines:
;       ftell
;	fclose
;----------------------------------------------------------------------
.proc close
		jsr	ftell
		fclose	(fp)
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;       Modifiées:
;               -
;       Utilisées:
;               fp
; Sous-routines:
;       ftell
;	fclose
;----------------------------------------------------------------------
.proc ftell
		lda	#CH376_READ_VAR32
		sta	CH376_COMMAND

		lda	#CH376_VAR_CURRENT_OFFSET
		sta	CH376_DATA

		lda	CH376_DATA
		sta	fpos

		lda	CH376_DATA
		sta	fpos+1

		lda	CH376_DATA
		sta	fpos+2

		lda	CH376_DATA
		sta	fpos+3

		rts
.endproc

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
;	fgets
;	reopen
;	close
;
; TODO: supprimer les appels reopen et close et les intégrer dans fgets
;----------------------------------------------------------------------
.proc fgetline
		; Compatibilité readline
;		jsr	reopen
;		bcs	end

		ldx	#LINE_MAX_SIZE
		lda	#<buffer
		ldy	#>buffer

		jsr	fgets

;		php
;		pha
;		jsr	close
;		pla
		tax
;		plp

		; bcs	end

		lda	#<buffer
		ldy	#>buffer

	end:
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;       Modifiées:
;               fp
;       Utilisées:
;               filename
;		submit_path
; Sous-routines:
;       chdir
;	fopen
;	fseek
;	print
;	crlf
;----------------------------------------------------------------------
.proc reopen
		; TODO: sauvegarder le pwd actuel pour pouvoir le restaurer
		; après la réouverture du fichier au cas où on a exécuté un cd

		; On se replace dans le répertoire d'origine au lancement
		; de submit
		; chdir	path

		fopen	(filename), O_RDONLY
		sta	fp
		stx	fp+1
		eor	fp+1
		bne	seek

		prints	"No such file or directory: "
		print	(filename)
		crlf

		sec
		lda	#ENOENT
		rts

	seek:
		jsr	fseek

		clc
		lda	#EOK
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	A: 0
;	X,Y: Inchangés
;
; Variables:
;	Modifiées:
;		stack_ptr
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc empty_stack
		lda	#$00
		sta	stack_ptr
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;
; Variables:
;	Modifiées:
;		stack_ptr
;		stack
;	Utilisées:
;		linenum
;		fpos_text
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc push
		; Voir pour utiliser un malloc et un pointeur vers la pile

		pha

		ldy	stack_ptr
		cpy	#MAX_LEVELS
		bcs	error103

		; Sauvegarde le numéro de la ligne suivant le call
		; (utile uniquement pour les messages d'erreurs)
		lda	linenum
		sta	stack,y
		lda	linenum+1
		sta	stack+1,y

		; Sauvegarde l'offset de la ligne suivant le call
		lda	fpos_text
		sta	stack+2,y
		lda	fpos_text+1
		sta	stack+3,y
		lda	fpos_text+2
		sta	stack+4,y
		lda	fpos_text+3
		sta	stack+5,y

		clc
		lda	#.sizeof(stack_item)
		adc	stack_ptr
		sta	stack_ptr

;		jsr	buffer_reset

		pla
		rts

	error103:
		pla

		; 43 Insufficient memory.
		; 103 DOs nested too deep.
		lda	#103
		rts

.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;
; Variables:
;	Modifiées:
;		stack_ptr
;		linenum
;		fpos
;		fpos_text
;	Utilisées:
;		stack
; Sous-routines:
;	buffer_reset
;----------------------------------------------------------------------
.proc pop
		pha

		lda	stack_ptr
		beq	error

		sec
		sbc	#.sizeof(stack_item)
		sta	stack_ptr
		tay

		; Restaure le numéro de ligne
		; (utile uniquement pour les messages d'erreurs)
		lda	stack,y
		sta	linenum
		lda	stack+1,y
		sta	linenum+1

		; Restaure l'offset de la ligne
		lda	stack+2,y
		sta	fpos
		sta	fpos_text
		lda	stack+3,y
		sta	fpos+1
		sta	fpos_text+1
		lda	stack+4,y
		sta	fpos+2
		sta	fpos_text+2
		lda	stack+5,y
		sta	fpos+3
		sta	fpos_text+3

		jsr	buffer_reset

		clc
		pla
		rts

	error:
		pla
		sec
		; Return without gosub
		lda	#$f1
		rts
.endproc

