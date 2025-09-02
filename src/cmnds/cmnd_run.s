
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

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------
.include "include/dbase.inc"
.include "macros/readline.mac"

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
.ifdef SUBMIT
	.export cmnd_exec
.endif

.export cmnd_run
.export set_errorlevel

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
		errlevel:
			.asciiz	"ERRORLEVEL"

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

.ifdef SUBMIT
	;----------------------------------------------------------------------
	; Équivalent à exec()
	; /!\ Nécessite un Kernel >= 202x.y
	;----------------------------------------------------------------------
	;
	; Entrée:
	;	pfac: adresse de la chaine (cf get_line)
	;
	; Sortie:
	;	C: 0->Ok, 1->Erreur
	;	ERRORLEVEL: code erreur de la commande si exécutée
	;	(non mis à jour en cas de non exécution de la commande)
	;
	; Variables:
	;	Modifiées:
	;		-
	;	Utilisées:
	;		pfac
	;
	; Sous-routines:
	;	XEXEC
	;	set_errorlevel
	;	-
	;----------------------------------------------------------------------
	.proc cmnd_exec
		ldx	#$01
		bne	cmnd_run+2
	.endproc
.endif

;----------------------------------------------------------------------
; Équivalent à system() ou fork()
;----------------------------------------------------------------------
;
; Entrée:
;	pfac: adresse de la chaine (cf get_line)
;
; Sortie:
;	C: 0->Ok, 1->Erreur
;	ERRORLEVEL: code erreur de la commande si exécutée
;	(non mis à jour en cas de non exécution de la commande)
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		pfac
;
; Sous-routines:
;	XEXEC
;	set_errorlevel
;----------------------------------------------------------------------
.proc cmnd_run
		ldx	#$00

		; Sauvegarde l'offset en cas d'erreur
;		sty	save_y+1

		; Sauvegarde la banque active
		; EXEC revient avec la banque 5 active
		lda	VIA2::PRA
		pha

		lda	pfac
		ldy	pfac+1
		.byte	$00, XEXEC

;		jsr	PrintRegs

		; Le code de retour du kernel est dans:
		; Kernel VERSION_2022_2 ($00) -> Acc (pas de code retour de la commande)
		; Kernel VERSION_2022_3 ($00) -> Acc (pas de code retour de la commande)
		; Kernel VERSION_2022_4 ($01) -> Y (code retour de  la commande dans A)
		;cmp	#EOK
		cpy	#EOK
		bne	error

		; Sauvegarde le code erreur de la commande dans ERRORLEVEL
		jsr	set_errorlevel

		; Restaure la banque
		pla
		sta	VIA2::PRA

		clc
		rts

	error:
		; A: ENOENT => commande ou exécutable inconnu
		; A: ENOEXEC => programme non relogeable

		; Restaure la banque
		pla
		sta	VIA2::PRA

		; Le code de retour du kernel est dans:
		; Kernel VERSION_2022_2 ($00) -> Acc (pas de code retour de la commande)
		; Kernel VERSION_2022_3 ($00)
		; Kernel VERSION_2022_4 ($01) -> Y (code retour de  la commande dans A)
		; lda	#ENOENT

		; prints	"Illegal command: "
		; print	(pfac)
		; crlf

	error16:
		; 10 Syntax error.
		; 16 *** Unrecognized command verb.
		lda	#16

	save_y:
		; ldy	#$00

		sec
		rts

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
.proc set_errorlevel
		ldx	#<errlevel
		ldy	#>errlevel
		jmp	set_bytevar
.endproc

.else
.proc set_errorlevel
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
		lda	errlevel,x
		sta	ident,x
		bne	loop1

		; Variable de type numérique
		lda	#'N'
		sta	param_type

		; Mise à jour de la variable
		jmp	cmnd_store
.endproc
.endif
