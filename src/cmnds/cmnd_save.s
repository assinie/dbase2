
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
.include "case.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.importzp line_ptr

.import opt_num

.import string
.importzp object
.importzp pfac
.import logic_value
.import bcd_value
.import param1

.import var_list
.import var_set_callback

.import fn_lower
.import fn_upper
.import fn_str
.import fn_ltoc
.import fn_dtoc

.import get_term_str
.import get_filename
.import skip_spaces

.import fputs
.import fp

.import push
.import pop

.import filter

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export cmnd_save

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
		unsigned short work_ptr

	.segment "DATA"
		unsigned char save_x
		unsigned char save_y

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
; SAVE TO <filename> [ALL LIKE|EXCEPT <pattern>]
;
; Entrée:
;	A: n° de token
;	X: offset des paramètres
;	Y: offset vers la fin de la ligne
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		opt_num
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc cmnd_save
		sty	save_y
		stx	save_x

		jsr	push
		bcs	error

		; Vérifier que <string> est un nom de fichier valide
;		prints	"save to "
;		print	string
;		crlf

		fopen	string, O_WRONLY | O_CREAT
		sta	fp
		stx	fp+1
		cmp	#$ff
		bne	set_filter

		cpx	#$ff
		beq	error72

	set_filter:
		; ALL LIKE / ALL EXCEPT /
		lda	opt_num
		bmi	save

		lda	line_ptr
		ldx	line_ptr+1
		ldy	save_x
		jsr	skip_spaces
		beq	error10

		; [[ Si on veut une expression chaine uniquement
;		lda	line_ptr
;		jsr	get_term_str
;		bcs	error45
;		; get_term_str: la chaine est à la fois dans param1 et string
;		; ]
;
;		; [ Si filtrage insensible à la casse, on passe le masque en majuscules...
;		jsr	fn_upper
;
;		;   et on le recopie dans param1
;		ldx	#$ff
;	loop:
;		inx
;		lda	string,x
;		sta	param1,x
;		bne	loop
		; ]
		; ]]

		; [[ Sinon, façon FILENAME
		lda	line_ptr
		jsr	get_filename
		bcs	error45

		; [ Si filtrage insensible à la casse, on passe le masque en majuscules...
		jsr	fn_upper

		;   et on le recopie dans param1
		ldx	#$ff
	loop:
		inx
		lda	string,x
		sta	param1,x
		bne	loop
		; ]
		; ]]

	save:
		; Initialise la routine d'affichage d'une entrée
		lda	#<save_entry
		ldy	#>save_entry
		jsr	var_set_callback

		jsr	var_list
		; TODO: tester un éventuel code erreur
		fclose	(fp)

		jsr	pop

		clc
		rts

	error10:
		; 10 Syntax error.
		lda	#10
		.byte	$2c

	error45:
		; 45 Not a Character expression.
		lda	#10
		.byte	$2c

	error72:
		; 6 Too many files are open.
		; 72  could not be opened.
		lda	#72

		pha
		jsr	pop
		pla
		clv

	error:
		ldy	save_y
		sec
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
;		opt_num ($ff -> pas de filtre, $00 -> ALL LIKE, $01 -> ALL EXCEPT
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc save_entry
		; Passe le nom de la variable en minuscules
		; [ save to
		ldx	#$ff
		ldy	#st_entry::name
		dey
	loop:
		inx
		iny
		lda	(object),y
		sta	string,x
		bne	loop

		stx	save_x

		lda	opt_num
		bmi	save

		jsr	filter			; C=0 -> Ok, C=1 -> Ok

		lda	opt_num
		beq	all_like

		bcc	save

		rts

	all_like:
		bcs	save
		rts

	save:
		ldx	save_x
		jsr	fn_lower
		; Ajoute " = "
		lda	#' '
		sta	string,x
		sta	string+2,x
		lda	#'='
		sta	string+1,x

		; Écris dans le fichier
		lda	#<string
		sta	PTR_READ_DEST
		lda	#>string
		sta	PTR_READ_DEST+1

		; Ajuste la longueur de la chaine
		txa
		adc	#$03

		ldy	#$00
		ldx	fp
		.byte	$00, XFWRITE

		; ]
		; [ display
;		print	(object)
;		cputc	' '
		; ]


		; Pointeur vers la donnée
		ldy	#st_entry::data_ptr
		lda	(object),y
		sta	work_ptr
		iny
		lda	(object),y
		sta	work_ptr+1

		; Type de la variable
		ldy	#st_entry::type
		lda	(object),y
		and	#$7f

		; [ display
;		pha
;
;		cputc
;		cputc	' '
;
;		; Affiche la taille de la variable
;		ldy	#st_entry::len
;		lda	(object),y
;		ldy	#$00
;		ldx	#$01
;		.byte	$00, XDECIM
;
;		cputc	' '
;		pla
		; ]


		do_case
			case_of 'C'
					; /!\ ATTENTION on ajoute 2 caractères à la chaine
					; donc string doit pouvoir contenir la taille maximale
					; de caractères d'une chaine +2
					ldy	#$ff
				loopC:
					iny
					lda	(work_ptr),y
					sta	string+1,y
					bne	loopC

					; Décale le marqueur de fin de chaine
					sta	string+2,y

					; Ajoute '"' avant et après la chaine
					lda	#'"'
					sta	string
					sta	string+1,y

			case_of 'N'
					ldy	#$03
				loopN:
					lda	(work_ptr),y
					sta	pfac,y
					dey
					bpl	loopN

					jsr	fn_str

			case_of 'D'
					ldy	#$03
				loopD:
					lda	(work_ptr),y
					sta	bcd_value,y
					dey
					bpl	loopD

					jsr	fn_dtoc

			case_of 'L'
					ldy	#$00
					lda	(work_ptr),y
					sta	logic_value

					jsr	fn_ltoc
		end_case

		; [ save to
		lda	#<string
		ldy	#>string
		jsr	fputs
		; ]
		; [ display
;		php
;		print	string
;		plp
;
;		bcc	end
;
;		cputc	'"'
		; ]

	end:
;		crlf

		rts
.endproc

