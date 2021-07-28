
'	SYMBOL CONSTANTS
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

' Defint Symbols

Const SYM_WHITESPACE:String  = " ~t~r"
Const SYM_SPACE:String       = " "
Const SYM_EOL:String         = "~n"
Const SYM_DQUOTE:String      = "~q"
Const SYM_LINECOMMENT:String = "'"
Const SYM_NUMBER:String      = "0123456789"
Const SYM_LOWER:String       = "abcdefghijklmnopqrstuvwxyz"
Const SYM_UPPER:String       = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
'Const SYM_SYMBOLS:String    = "!#$%&'()*+:Int			= 6-./:;<=>?@[]^_`{|}"
Const SYM_ALPHA:String       = SYM_LOWER+SYM_UPPER
'Const SYM_7BIT:String       = SYM_SPACE++SYM_NUMBER+SYM_UPPER+SYM_LOWER+SYM_SYMBOLS

Const TK_EOF:Int = $FFFF

'	CONTROL CHARACTERS
Const TK_TAB:Int 			= 9
Const TK_LF:Int 			= 10
Const TK_CR:Int 			= 13
Const TK_EOL:Int 			= TK_CR

'	COMPOUND SYMBOLS

Const TK_MULTILINE:Int		= 512	'	..
Const TK_NOT_EQUAL:Int		= 513	'	<>
Const TK_LT_OR_EQUAL:Int	= 514	'	<=
Const TK_GR_OR_EQUAL:Int	= 515	'	>=
Const TK_ASSIGN_PLUS:Int	= 516	'	:+	
Const TK_ASSIGN_MINUS:Int	= 517	'	:-
Const TK_ASSIGN_MUL:Int		= 518	'	:*
Const TK_ASSIGN_DIV:Int		= 518	'	:/
Const TK_BITWISEAND:Int		= 519	'	:&
Const TK_BITWISEOR:Int		= 520	'	:|
Const TK_BITWISEXOR:Int		= 521	'	:~

'	IDENTIFIERS

Const TK_Invalid:Int 		= 600	'	Any token flagged as invalid
Const TK_Comment:Int 		= 601	'	' Comment
Const TK_Alpha:Int			= 602	'	Unidentified identifier
Const TK_Identifier:Int		= 603	'	Identifier identifier
Const TK_QuotedString:Int	= 604	'	"String"
Const TK_Number:Int			= 605	' 	Number

'	KEYWORDS

Const TK_ALIAS:Int			= 610
Const TK_AND:Int			= 611
Const TK_ASC:Int			= 612
Const TK_ASSERT:Int			= 613
Const TK_BYTE:Int			= 614
Const TK_CASE:Int			= 615
Const TK_CATCH:Int			= 616
Const TK_CHR:Int			= 617
Const TK_CONST:Int			= 618
Const TK_CONTINUE:Int		= 619
Const TK_DEFAULT:Int		= 620
Const TK_DEFDATA:Int		= 	620
Const TK_DELETE:Int			= 621
Const TK_DOUBLE:Int			= 622
Const TK_EACHIN:Int			= 623
Const TK_ELSE:Int			= 624
Const TK_ELSEIF:Int			= 625
Const TK_END:Int			= 626
Const TK_ENDEXTERN:Int		= 627
Const TK_ENDFUNCTION:Int	= 628
Const TK_ENDIF:Int			= 629
Const TK_ENDINTERFACE:Int	= 630
Const TK_ENDMETHOD:Int		= 631
Const TK_ENDREM:Int			= 632
Const TK_ENDSELECT:Int		= 633
Const TK_ENDSTRUCT:Int		= 634
Const TK_ENDTRY:Int			= 635
Const TK_ENDTYPE:Int		= 636
Const TK_ENDWHILE:Int		= 637
Const TK_EXIT:Int			= 638
Const TK_EXPORT:Int			= 639
Const TK_EXTENDS:Int		= 640
Const TK_EXTERN:Int			= 641
Const TK_FALSE:Int			= 642
Const TK_FIELD:Int			= 643
Const TK_FINAL:Int			= 644
Const TK_FINALLY:Int		= 645
Const TK_FLOAT:Int			= 646
Const TK_FOR:Int			= 647
Const TK_FOREVER:Int		= 648
Const TK_FRAMEWORK:Int		= 649
Const TK_FUNCTION:Int		= 650
Const TK_GLOBAL:Int			= 651
Const TK_GOTO:Int			= 652
Const TK_IF:Int				= 653
Const TK_IMPLEMENETS:Int	= 654
Const TK_IMPORT:Int			= 655
Const TK_INCBIN:Int			= 656
Const TK_INCBINLEN:Int		= 657
Const TK_INCBINPTR:Int		= 658
Const TK_INCLUDE:Int		= 659
Const TK_INT:Int			= 660
Const TK_INTERFACE:Int		= 661
Const TK_LEN:Int			= 662
Const TK_LOCAL:Int			= 663
Const TK_LONG:Int			= 664
Const TK_METHOD:Int			= 665
Const TK_MOD:Int			= 666
Const TK_MODULE:Int			= 667
Const TK_MODULEINFO:Int		= 668
Const TK_NEW:Int			= 669
Const TK_NEXT:Int			= 670
Const TK_NODEBUG:Int		= 671
Const TK_NOT:Int			= 672
Const TK_NULL:Int			= 673
Const TK_OBJECT:Int			= 674
Const TK_OPERATOR:Int		= 675
Const TK_OR:Int				= 676
Const TK_PI:Int				= 677
Const TK_PRIVATE:Int		= 678
Const TK_PROTECTED:Int		= 679
Const TK_PTR:Int			= 680
Const TK_PUBLIC:Int			= 681
Const TK_READDATA:Int		= 682
Const TK_READONLY:Int		= 683
Const TK_RELEASE:Int		= 684
Const TK_REM:Int			= 685
Const TK_REPEAT:Int			= 686
Const TK_RESTOREDATA:Int	= 687
Const TK_RETURN:Int			= 688
Const TK_SAR:Int			= 689
Const TK_SELECT:Int			= 690
Const TK_SELF:Int			= 691
Const TK_SHL:Int			= 692
Const TK_SHORT:Int			= 693
Const TK_SHR:Int			= 694
Const TK_SIZEOF:Int			= 695
Const TK_SIZE_T:Int			= 696
Const TK_STEP:Int			= 697
Const TK_STRICT:Int			= 698
Const TK_STRING:Int			= 699
Const TK_STRUCT:Int			= 700
Const TK_SUPER:Int			= 701
Const TK_SUPERSTRICT:Int	= 702
Const TK_THEN:Int			= 703
Const TK_THROW:Int			= 704
Const TK_TO:Int				= 705
Const TK_TRUE:Int			= 706
Const TK_TRY:Int			= 707
Const TK_TYPE:Int			= 708
Const TK_UNIT:Int			= 709
Const TK_UNLONG:Int			= 710
Const TK_UNTIL:Int			= 711
Const TK_VAR:Int			= 712
Const TK_VARPTR:Int			= 713
Const TK_WEND:Int			= 714
Const TK_WHERE:Int			= 715
Const TK_WHILE:Int			= 716

'	SINGLE CHARACTER TOKENS
Const TK_exclamation:Int 	= TK_DOUBLE	'	!	(double)
Const TK_dquote:Int 		= 34		'	"
Const TK_hash:Int 			= TK_FLOAT	'	#	(float)
Const TK_dollar:Int			= TK_STRING	'	$	(string)
Const TK_percent:Int		= TK_INT	'	%	(int)
Const TK_ampersand:Int		= 38		'	&	
Const TK_squote:Int 		= 39		'	'
Const TK_lparen:Int			= 40		'	(
Const TK_rparen:Int			= 41		'	)
Const TK_asterisk:Int		= 42		'	*
Const TK_plus:Int			= 43		'	+
Const TK_comma:Int			= 44		'	,
Const TK_hyphen:Int			= 45		'	-
Const TK_period:Int			= 46		'	.
Const TK_solidus:Int		= 47		'	/
Const TK_colon:Int			= 58		'	:
Const TK_semicolon:Int		= 59		'	;
Const TK_lessthan:Int		= 60		'	<
Const TK_equals:Int			= 61		'	=
Const TK_greaterthan:Int	= 62		'	>
Const TK_question:Int		= 63		'	?
Const TK_at:Int				= 64		'	@
Const TK_lcrotchet:Int		= 91		'	[
Const TK_backslash:Int		= 92		'	\
Const TK_rcrotchet:Int		= 93		'	]
Const TK_circumflex:Int		= 94		'	^
Const TK_underscore:Int		= 95		'	_
Const TK_backtick:Int		= 96		'	`
Const TK_lbrace:Int			= 123		'	{
Const TK_pipe:Int			= 124		'	|
Const TK_rbrace:Int			= 125		'	}
Const TK_tilde:Int 			= 126		'	~




