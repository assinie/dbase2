;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes
.feature labels_without_colons

.include "telestrat.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
; From math.s
.importzp pfac
.importzp sfac

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export strbin
.export binstr
;;.exportzp pfac
;.export strbuf

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short ptr01	;    =$00                  ;input string pointer
		unsigned char stridx	;   =ptr01+2              ;string index
;		unsigned long pfac	;     =stridx+1             ;primary accumulator
;		unsigned long sfac	;     =pfac+s_fac           ;secondary accumulator
		;
		;	------------------------------------------------------
		;	Define the above to suit your application.  Moving the
		;	accumulators to absolute storage will result in an
		;	approximate 20 percent increase in execution time &
		;	will require some program restructuring to avoid out-
		;	of-range relative branches.
		;	------------------------------------------------------
.popseg

.pushseg
	;DYNAMIC STORAGE
	;
	.segment "DATA"
		bitsdig:  .res 1                 ;bits per digit
		curntnum: .res 1                 ;numeral being processed
		radxflag: .res 1                 ;$80 = processing base-10
		valdnum:  .res 1                 ;valid range +1 for selected radix
.popseg

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
;ATOMIC CONSTANTS
;
;;_origin_ =$02000               ;assembly address
;
;	------------------------------------------
;	Define the above to suit your application.
;	------------------------------------------
;
a_maskuc =%01011111            ;case conversion mask
a_hexnum ='A'-'9'-1            ;hex to decimal difference
n_radix  =4                    ;number of supported radixes
s_fac    =4                    ;binary accumulator size

;----------------------------------------------------------------------
;			Chaînes statiques
;----------------------------------------------------------------------
.pushseg
	;CONVERSION TABLES
	;
	.segment "RODATA"
		basetab:  .byte 10,2,8,16       ;number bases per radix
		bitstab:  .byte 3,1,3,4         ;bits per digit per radix
		radxtab:  .byte " %@$"          ;valid radix symbols
.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"

;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                                                                             *
;*                CONVERT ASCII NUMBER STRING TO 32-BIT BINARY                 *
;*                                                                             *
;*                             by BigDumbDinosaur                              *
;*                                                                             *
;* This 6502 assembly language program converts a null-terminated ASCII number *
;* string into a 32-bit unsigned binary value in little-endian format.  It can *
;* accept a number in binary, octal, decimal or hexadecimal format.            *
;*                                                                             *
;* --------------------------------------------------------------------------- *
;*                                                                             *
;* Copyright (C)1985 by BCS Technology Limited.  All rights reserved.          *
;*                                                                             *
;* Permission is hereby granted to copy and redistribute this software,  prov- *
;* ided this copyright notice remains in the source code & proper  attribution *
;* is given.  Any redistribution, regardless of form, must be at no charge  to *
;* the end user.  This code MAY NOT be incorporated into any package  intended *
;* for sale unless written permission has been given by the copyright holder.  *
;*                                                                             *
;* THERE IS NO WARRANTY OF ANY KIND WITH THIS SOFTWARE.  It's free, so no mat- *
;* ter what, you'll get your money's worth.                                    *
;*                                                                             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;	Calling Syntax:
;
;		ldx #<numstr
;		ldy #>numstr
;		jsr strbin
;		bcs error
;
;	All registers are modified.  The result of the conversion is left in
;	location PFAC in unsigned, little-endian format (see source code).
;	The contents of PFAC are undefined if strbin exits with an error.
;	The maximum number that can be converted is 4,294,967,295 or (2^32)-1.
;
;	numstr must point to a null-terminated character string in the format:
;
;		[%|@|$]DDD...DDD
;
;	where %, @ or $ are optional radices specifying, respectively, base-2,
;	base-8 or base-16.  If no radix is specified, base-10 is assumed.
;
;	DDD...DDD represents the characters that comprise the number that is
;	to be converted.  Permissible values for each instance of D are:
;
;		Radix  Description  D - D
;		-------------------------
;		  %    Binary       0 - 1
;		  @    Octal        0 - 7
;		 None  Decimal      0 - 9
;		  $    Hexadecimal  0 - 9
;		                    A - F
;		-------------------------
;
;	Conversion is not case-sensitive.  Leading zeros are permissible, but
;	not leading blanks.  The maximum string length including the null
;	terminator is 127.  An error will occur if a character in the string
;	to be converted is not appropriate for the selected radix, the con-
;	verted value exceeds $FFFFFFFF or an undefined radix is specified.
;
;================================================================================
;
;
;================================================================================
;
;CONVERT NULL-TERMINATED STRING TO 32 BIT BINARY
;
;;         *=_origin_
;
strbin   stx ptr01             ;save string pointer LSB
         sty ptr01+1           ;save string pointer MSB
         lda #0
         ldx #s_fac-1          ;accumulator size
;
strbin01 sta pfac,x            ;clear
         dex
         bpl strbin01

	sta radxflag           ; -HCL- correction, initialise radxflag
	sta stridx		; -HCL- correction, initialise stridx (sinon pb quand il n'y a pas de radix)
;
;	------------------------
;	process radix if present
;	------------------------
;
         tay                   ;starting string index
         clc                   ;assume no error for now
         lda (ptr01),y         ;get a char
         bne strbin02
;
         rts                   ;null string, so exit
;
strbin02 ldx #n_radix-1
;
strbin03 cmp radxtab,x         ;recognized radix?
         beq strbin04          ;yes
;
         dex
         bpl strbin03          ;try next
;
         stx radxflag          ;assuming decimal...
         inx                   ;which might be wrong
;
strbin04 lda basetab,x         ;number bases table
         sta valdnum           ;set valid numeral range
         lda bitstab,x         ;get bits per digit
         sta bitsdig           ;store
         txa                   ;was radix specified?
         beq strbin06          ;no
;
         iny                   ;move past radix
;
strbin05 sty stridx            ;save string index
;
;	--------------------------------
;	process number portion of string
;	--------------------------------
;
strbin06 clc                   ;assume no error for now
         lda (ptr01),y         ;get numeral
         beq strbin17          ;end of string
;
         inc stridx            ;point to next
         cmp #'a'              ;check char range
         bcc strbin07          ;not ASCII LC
;
         cmp #'z'+1
         bcs strbin08          ;not ASCII LC
;
         and #a_maskuc         ;do case conversion
;
strbin07 sec
;
strbin08 sbc #'0'              ;change numeral to binary
         bcc strbin16          ;numeral > 0
;
         cmp #10
         bcc strbin09          ;numeral is 0-9
;
         sbc #a_hexnum         ;do a hex adjust
;
strbin09 cmp valdnum           ;check range
         bcs strbin17          ;out of range
;
         sta curntnum          ;save processed numeral
         bit radxflag          ;working in base 10?
         bpl strbin11          ;no
;
;	-----------------------------------------------------------
;	Prior to combining the most recent numeral with the partial
;	result, it is necessary to left-shift the partial result
;	result 1 digit.  The operation can be described as N*base,
;	where N is the partial result & base is the number base.
;	N*base with binary, octal & hex is a simple repetitive
;	shift.  A simple shift won't do with decimal, necessitating
;	an (N*8)+(N*2) operation.  PFAC is copied to SFAC to gener-
;	ate the N*2 term.
;	-----------------------------------------------------------
;
         ldx #0
         ldy #s_fac            ;accumulator size
         clc
;
strbin10 lda pfac,x            ;N
         rol                   ;N=N*2
         sta sfac,x
         inx
         dey
         bne strbin10
;
         bcs strbin17          ;overflow = error
;
strbin11 ldx bitsdig           ;bits per digit
;
strbin12 asl pfac              ;compute N*base for binary,...
         rol pfac+1            ;octal &...
         rol pfac+2            ;hex or...
         rol pfac+3            ;N*8 for decimal
         bcs strbin17          ;overflow
;
         dex
         bne strbin12          ;next shift
;
         bit radxflag          ;check base
         bpl strbin14          ;not decimal
;
;	-------------------
;	compute (N*8)+(N*2)
;	-------------------
;
         ldx #0                ;accumulator index
         ldy #s_fac
;
strbin13 lda pfac,x            ;N*8
         adc sfac,x            ;N*2
         sta pfac,x            ;now N*10
         inx
         dey
         bne strbin13
;
         bcs strbin17          ;overflow
;
;	-------------------------------------
;	add current numeral to partial result
;	-------------------------------------
;
strbin14 clc
         lda pfac              ;N
         adc curntnum          ;N=N+D
         sta pfac
         ldx #1
         ldy #s_fac-1
;
strbin15 lda pfac,x
         adc #0                ;account for carry
         sta pfac,x
         inx
         dey
         bne strbin15
;
         bcs strbin17          ;overflow
;
;	----------------------
;	ready for next numeral
;	----------------------
;
         ldy stridx            ;string index
         bpl strbin06          ;get another numeral
;
;	----------------------------------------------
;	if string length > 127 fall through with error
;	----------------------------------------------
;
strbin16 sec                   ;flag an error
;
strbin17 rts                   ;done


;===============================================================================

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                                                                             *
;*                CONVERT 32-BIT BINARY TO ASCII NUMBER STRING                 *
;*                                                                             *
;*                             by BigDumbDinosaur                              *
;*                                                                             *
;* This 6502 assembly language program converts a 32-bit unsigned binary value *
;* into a null-terminated ASCII string whose format may be in  binary,  octal, *
;* decimal or hexadecimal.                                                     *
;*                                                                             *
;* --------------------------------------------------------------------------- *
;*                                                                             *
;* Copyright (C)1985 by BCS Technology Limited.  All rights reserved.          *
;*                                                                             *
;* Permission is hereby granted to copy and redistribute this software,  prov- *
;* ided this copyright notice remains in the source code & proper  attribution *
;* is given.  Any redistribution, regardless of form, must be at no charge  to *
;* the end user.  This code MAY NOT be incorporated into any package  intended *
;* for sale unless written permission has been given by the copyright holder.  *
;*                                                                             *
;* THERE IS NO WARRANTY OF ANY KIND WITH THIS SOFTWARE.  It's free, so no mat- *
;* ter what, you're getting a great deal.                                      *
;*                                                                             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;	CALLING SYNTAX:
;
;	        LDA #RADIX         ;radix character, see below
;	        LDX #<OPERAND      ;binary value address LSB
;	        LDY #>OPERAND      ;binary value address MSB
;	        (ORA #%10000000)   ;radix suppression, see below
;	        JSR BINSTR         ;perform conversion
;	        STX ZPPTR          ;save string address LSB
;	        STY ZPPTR+1        ;save string address MSB
;	        TAY                ;string length
;	LOOP    LDA (ZPPTR),Y      ;copy string to...
;	        STA MYSPACE,Y      ;safe storage, will include...
;	        DEY                ;the terminator
;	        BPL LOOP
;
;	CALLING PARAMETERS:
;
;	.A      Conversion radix, which may be any of the following:
;
;	        '%'  Binary.
;	        '@'  Octal.
;	        '$'  Hexadecimal.
;
;	        If the radix is not one of the above characters decimal will be
;	        assumed.  Binary, octal & hex conversion will prepend the radix
;	        character to the string.  To suppress this feature set bit 7 of
;	        the radix.
;
;	.X/.Y   The address of the 32-bit binary value (operand) that is to be
;	        converted.  The operand must be in little-endian format.
;
;	REGISTER RETURNS:
;
;	.A      The printable string length.  The exact length will depend on
;	        the radix that has been selected, whether the radix is to be
;	        prepended to the string & the number of significant digits.
;	        Maximum possible printable string lengths for each radix type
;	        are as follows:
;
;	        %  Binary   33
;	        @  Octal    12
;	           Decimal  11
;	        $  Hex       9
;
;	.X/.Y   The LSB/MSB address at which the null-terminated conversion
;	        string will be located.  The string will be assembled into a
;	        statically allocated buffer and should be promptly copied to
;	        user-defined safe storage.
;
;	.C      The carry flag will always be clear.
;
;	APPROXIMATE EXECUTION TIMES in CLOCK CYCLES:
;
;	        Binary    5757
;	        Octal     4533
;	        Decimal  13390
;	        Hex       4373
;
;	The above execution times assume the operand is $FFFFFFFF, the radix
;	is to be prepended to the conversion string & all workspace other than
;	the string buffer is on zero page.  Relocating ZP workspace to absolute
;	memory will increase execution time approximately 8 percent.
;
;================================================================================
;
;ATOMIC CONSTANTS
;
;_origin_ =$02000               ;assembly address
;_zpage_  =$00                  ;start of ZP storage
;
;	------------------------------------------
;	Modify the above to suit your application.
;	------------------------------------------
;
a_hexdec ='A'-'9'-2            ;hex to decimal difference
m_bits   =32                   ;operand bit size
m_cbits  =48                   ;workspace bit size
m_strlen =m_bits+1             ;maximum printable string length
;n_radix  =4                    ;number of supported radices
s_pfac   =m_bits/8             ;primary accumulator size
s_ptr    =2                    ;pointer size
s_wrkspc =m_cbits/8            ;conversion workspace size
;
;================================================================================
;
;ZERO PAGE ASSIGNMENTS
;
;		unsigned short ptr01	; ptr01    =_zpage_              ;string storage pointer
;
;	---------------------------------
;	The following may be relocated to
;	absolute storage if desired.
;	---------------------------------
;
;		unsigned long pfac			; =ptr01+s_ptr          ;primary accumulator

.pushseg
	.segment "DATA"
			unsigned char wrkspc01[s_wrkspc]	; =pfac+s_pfac          ;conversion...
			unsigned char wrkspc02[s_wrkspc]	; =wrkspc01+s_wrkspc    ;workspace
			unsigned char formflag			; =wrkspc02+s_wrkspc    ;string format flag
			unsigned char radix			; =formflag+1           ;radix index
			; unsigned char stridx			; =radix+1              ;string buffer index
.popseg
;
;================================================================================
;
;CONVERT 32-BIT BINARY TO NULL-TERMINATED ASCII NUMBER STRING
;
;	----------------------------------------------------------------
;	WARNING! If this code is run on an NMOS MPU it will be necessary
;	         to disable IRQs during binary to BCD conversion unless
;	         the target system's IRQ handler clears decimal mode.
;	         Refer to the FACBCD subroutine.
;	----------------------------------------------------------------
;
;         *=_origin_
;
binstr   stx ptr01             ;operand pointer LSB
         sty ptr01+1           ;operand pointer MSB
         tax                   ;protect radix
         ldy #s_pfac-1         ;operand size
;
binstr01 lda (ptr01),y         ;copy operand to...
         sta pfac,y            ;workspace
         dey
         bpl binstr01
;
         iny
         sty stridx            ;initialize string index
;
;	--------------
;	evaluate radix
;	--------------
;
         txa                   ;radix character
         asl                   ;extract format flag &...
         ror formflag          ;save it
         lsr                   ;extract radix character
         ldx #n_radix-1        ;total radices
;
binstr03 cmp radxtab2,x        ;recognized radix?
         beq binstr04          ;yes
;
         dex
         bne binstr03          ;try next
;
;	------------------------------------
;	radix not recognized, assume decimal
;	------------------------------------
;
binstr04 stx radix             ;save radix index for later
         txa                   ;converting to decimal?
         bne binstr05          ;no
;
;	------------------------------
;	prepare for decimal conversion
;	------------------------------
;
         jsr facbcd            ;convert operand to BCD
         lda #0
         beq binstr09          ;skip binary stuff
;
;	-------------------------------------------
;	prepare for binary, octal or hex conversion
;	-------------------------------------------
;
binstr05 bit formflag
         bmi binstr06          ;no radix symbol wanted
;
         lda radxtab2,x        ;radix table
         sta strbuf            ;prepend to string
         inc stridx            ;bump string index
;
binstr06 ldx #0                ;operand index
         ldy #s_wrkspc-1       ;workspace index
;
binstr07 lda pfac,x            ;copy operand to...
         sta wrkspc01,y        ;workspace in...
         dey                   ;big-endian order
         inx
         cpx #s_pfac
         bne binstr07
;
         lda #0
;
binstr08 sta wrkspc01,y        ;pad workspace
         dey
         bpl binstr08
;
;	----------------------------
;	set up conversion parameters
;	----------------------------
;
binstr09 sta wrkspc02          ;initialize byte counter
         ldy radix             ;radix index
         lda numstab,y         ;numerals in string
         sta wrkspc02+1        ;set remaining numeral count
         lda bitstab2,y        ;bits per numeral
         sta wrkspc02+2        ;set
         lda lzsttab,y         ;leading zero threshold
         sta wrkspc02+3        ;set
;
;	--------------------------
;	generate conversion string
;	--------------------------
;
binstr10 lda #0
         ldy wrkspc02+2        ;bits per numeral
;
binstr11 ldx #s_wrkspc-1       ;workspace size
         clc                   ;avoid starting carry
;
binstr12 rol wrkspc01,x        ;shift out a bit...
         dex                   ;from the operand or...
         bpl binstr12          ;BCD conversion result
;
         rol                   ;bit to .A
         dey
         bne binstr11          ;more bits to grab
;
         tay                   ;if numeral isn't zero...
         bne binstr13          ;skip leading zero tests
;
         ldx wrkspc02+1        ;remaining numerals
         cpx wrkspc02+3        ;leading zero threshold
         bcc binstr13          ;below it, must convert
;
         ldx wrkspc02          ;processed byte count
         beq binstr15          ;discard leading zero
;
binstr13 cmp #10               ;check range
         bcc binstr14          ;is 0-9
;
         adc #a_hexdec         ;apply hex adjust
;
binstr14 adc #'0'              ;change to ASCII
         ldy stridx            ;string index
         sta strbuf,y          ;save numeral in buffer
         inc stridx            ;next buffer position
         inc wrkspc02          ;bytes=bytes+1
;
binstr15 dec wrkspc02+1        ;numerals=numerals-1
         bne binstr10          ;not done
;
;	-----------------------
;	terminate string & exit
;	-----------------------
;
         lda #0
         ldx stridx            ;printable string length
         sta strbuf,x          ;terminate string
         txa
         ldx #<strbuf          ;converted string LSB
         ldy #>strbuf          ;converted string MSB
         clc                   ;all okay
         rts
;
;================================================================================
;
;CONVERT PFAC INTO BCD
;
;	---------------------------------------------------------------
;	Uncomment noted instructions if this code is to be used  on  an
;	NMOS system whose interrupt handlers do not clear decimal mode.
;	---------------------------------------------------------------
;
facbcd   ldx #s_pfac-1         ;primary accumulator size -1
;
facbcd01 lda pfac,x            ;value to be converted
         pha                   ;protect
         dex
         bpl facbcd01          ;next
;
         lda #0
         ldx #s_wrkspc-1       ;workspace size
;
facbcd02 sta wrkspc01,x        ;clear final result
         sta wrkspc02,x        ;clear scratchpad
         dex
         bpl facbcd02
;
         inc wrkspc02+s_wrkspc-1
         ;php                   ;!!! uncomment for NMOS MPU !!!
         ;sei                   ;!!! uncomment for NMOS MPU !!!
         sed                   ;select decimal mode
         ldy #m_bits-1         ;bits to convert -1
;
facbcd03 ldx #s_pfac-1         ;operand size
         clc                   ;no carry at start
;
facbcd04 ror pfac,x            ;grab LS bit in operand
         dex
         bpl facbcd04
;
         bcc facbcd06          ;LS bit clear
;
         clc
         ldx #s_wrkspc-1
;
facbcd05 lda wrkspc01,x        ;partial result
         adc wrkspc02,x        ;scratchpad
         sta wrkspc01,x        ;new partial result
         dex
         bpl facbcd05
;
         clc
;
facbcd06 ldx #s_wrkspc-1
;
facbcd07 lda wrkspc02,x        ;scratchpad
         adc wrkspc02,x        ;double &...
         sta wrkspc02,x        ;save
         dex
         bpl facbcd07
;
         dey
         bpl facbcd03          ;next operand bit
;
         ;plp                   ;!!! uncomment for NMOS MPU !!!
         cld			; -HCL- Ajout
         ldx #0
;
facbcd08 pla                   ;operand
         sta pfac,x            ;restore
         inx
         cpx #s_pfac
         bne facbcd08          ;next
;
         rts
;
;================================================================================
.pushseg
	.segment "RODATA"
		;
		;PER RADIX CONVERSION TABLES
		;
		bitstab2:  .byte 4,1,3,4         ;bits per numeral
		lzsttab:   .byte 2,9,2,3         ;leading zero suppression thresholds
		numstab:   .byte 12,48,16,12     ;maximum numerals
		radxtab2:  .byte 0,"%@$"         ;recognized symbols
.popseg

;
;================================================================================
;
.pushseg
	.segment "DATA"
		;STATIC STORAGE
		;
		unsigned char strbuf[m_strlen+1]	; *=*+m_strlen+1        ;conversion string buffer
		;
.popseg
;================================================================================

