
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
.import main_fp
.importzp line_ptr
.import submit_line

.import opt_num

.import string

.import affectation
.import fgets

.import file_push
.import file_pop
.import buffer_reset
.import file_noreopen

.import cmnd_clear

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_restore

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
OPT_MEMORY = $03

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"

	.segment "DATA"
		unsigned char save_y
;		unsigned char line[80]
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
; RESTORE FROM <file> [ADDITIVE]
;
; Note: affectation fait appel à _find_cmnd qui utilise submit_line
; 	et non line_ptr, donc on charge le fichier dans submit_line
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
.proc cmnd_restore
		sty	save_y

		; Indique cmnd_restore en cours pour file_reopen dans fgets
		; (file_noreopen non nul)
		sty	file_noreopen

		jsr	buffer_reset
		jsr	file_push
		bcs	error

	;.ifndef SUBMIT
	;	; Option ADDITIVE?
	;	lda	opt_num
	;	bpl	restore

		; Non, on efface toute les variables
	;	lda	#OPT_MEMORY
	;	sta	opt_num
	;	jsr	cmnd_clear
	;.endif

	restore:
		; Vérifier que <string> est un nom de fichier valide
;		prints	"restore from "
;		print	string
;		crlf

		fopen	string, O_RDONLY
		sta	main_fp
		stx	main_fp+1
	;	cmp	#$ff
	;	bne	getline
	;	cpx	#$ff
	;	beq	error1
		eor	main_fp+1
		beq	error1

	.ifndef SUBMIT
		; Option ADDITIVE?
		lda	opt_num
		bpl	getline

		; Non, on efface toutes les variables
		lda	#OPT_MEMORY
		sta	opt_num
		jsr	cmnd_clear
	.endif

	getline:
		lda	line_ptr
		ldy	line_ptr+1
		ldx	#LINE_MAX_SIZE
		jsr	fgets

		; Fin de fichier?
		bcs	end

		; Ligne vide?
		ldy	#$00
		lda	(line_ptr),y
		beq	getline

		; Commentaire?
		cmp	#';'
		beq	getline

		cmp	#'#'
		beq	getline

;		print	(line_ptr)
;		crlf

		; /!\ Copie la ligne dans submit_line
		; Hack pour _find_cmnd
		ldy	#$ff
	loop:
		iny
		lda	(line_ptr),y
		sta	submit_line,y
		bne	loop

		; /!\ La fonction affectation autorise
		;     l'utilisation de fonctions dans le fichier
		;     Ex.:  c = os()
		;     Utiliser une autre fonction à la place?
		; C=1 pour le délimiteur du nom de variable soit uniquement ' '
		; C=0 pour n'importe quel caractère non alphanumérique
		clc
		lda	line_ptr
		ldx	line_ptr+1
		ldy	#$00
		jsr	affectation

		clv
		bcs	error10
		; On vérifie qu'on est bien à la fin de la ligne
		; sinon "c = 45er" ne remontera pas d'erreur
		lda	submit_line,y
		beq	getline

	error10:
		; 10 Syntax error.
		sty	save_y

		fclose	(main_fp)

		jsr	file_pop

		lda	#10
	;	ldy	save_y
	;	sec
	;	rts
		jmp	error

	end:
		; Signale la fin de cmnd_restore pour submit_reopend ans fgets
		lda	#$00
		sta	file_noreopen

		fclose	(main_fp)
		jsr	file_pop
		; clc
		rts

	error1:
		jsr	file_pop

		; 1 File does not exist.
		; 29 File is not accessible.
		lda	#01

	error:
		; Signale la fin de cmnd_restore pour submit_reopend ans fgets
		ldy	#$00
		sty	file_noreopen

		ldy	save_y
		sec
		rts

.endproc


