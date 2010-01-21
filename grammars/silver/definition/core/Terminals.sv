grammar silver:definition:core;

lexer class KEYWORD dominates TWO;
lexer class SIX dominates KEYWORD;
lexer class TWO dominates ZERO;
lexer class SEVEN dominates SIX;
lexer class ZERO;

terminal ReadFile_kwd 		/readFile/ 	lexer classes {KEYWORD};
terminal WriteFile_kwd 		/writeFile/	lexer classes {KEYWORD};
terminal AppendFile_kwd 	/appendFile/	lexer classes {KEYWORD};
terminal EnvVar_kwd 		/envVar/ 	lexer classes {KEYWORD};
terminal System_kwd 		/system/ 	lexer classes {KEYWORD};
terminal CWD_kwd 		/cwd/   	lexer classes {KEYWORD};
terminal IsFile_kwd 		/isFile/ 	lexer classes {KEYWORD};
terminal IsDirectory_kwd 	/isDirectory/ 	lexer classes {KEYWORD};
terminal Mkdir_kwd		/mkdir/		lexer classes {KEYWORD};
terminal Print_kwd 		/print/ 	lexer classes {KEYWORD};
terminal ListContents_kwd	/listContents/	lexer classes {KEYWORD};
terminal UnsafeIO_kwd 		/unsafeio/ 	lexer classes {KEYWORD};
terminal GenInt_kwd 		/genInt/ 	lexer classes {KEYWORD};
terminal FileTime_kwd 		/fileTime/ 	lexer classes {KEYWORD};
terminal Return_kwd /return/ lexer classes {KEYWORD};
terminal Function_kwd /function/ lexer classes {KEYWORD};
terminal Decorated_kwd /Decorated/ lexer classes {KEYWORD};
--terminal Syntax_kwd  /syntax/ lexer classes {KEYWORD} ;
terminal Concrete_kwd /concrete/ lexer classes {KEYWORD};
--terminal Start_kwd /start/ lexer classes {KEYWORD} ;
terminal Aspect_kwd /aspect/ lexer classes {KEYWORD};
terminal Attribute_kwd /attribute/   lexer classes {KEYWORD} ;
terminal Synthesized_kwd /synthesized/ lexer classes {KEYWORD} ;
terminal Inherited_kwd /inherited/   lexer classes {KEYWORD} ;
terminal Length_kwd /length/ lexer classes {KEYWORD};
terminal IndexOf_kwd /indexOf/ lexer classes {KEYWORD};
terminal SubString_kwd /substring/ lexer classes {KEYWORD};
terminal Error_kwd /error/ lexer classes {KEYWORD};
terminal ToInt_kwd /toInt/ lexer classes {KEYWORD};
terminal ToFloat_kwd /toFloat/ lexer classes {KEYWORD};
terminal ToString_kwd /toString/ lexer classes {KEYWORD};
terminal IsDigit_kwd /isDigit/ lexer classes {KEYWORD};
terminal IsAlpha_kwd /isAlpha/ lexer classes {KEYWORD};
terminal IsSpace_kwd /isSpace/ lexer classes {KEYWORD};
terminal IsLower_kwd /isLower/ lexer classes {KEYWORD};
terminal IsUpper_kwd /isUpper/ lexer classes {KEYWORD};
terminal New_kwd /new/ lexer classes {KEYWORD};
terminal Decorate_kwd /decorate/ lexer classes {KEYWORD};
terminal True_kwd /true/ lexer classes {KEYWORD};
terminal False_kwd /false/ lexer classes {KEYWORD};
terminal Import_kwd  /import/ lexer classes {KEYWORD} ;
terminal Imports_kwd  /imports/ lexer classes {KEYWORD} ;
terminal Exports_kwd  /exports/ lexer classes {KEYWORD} ;
terminal Build_kwd    'build'   lexer classes {KEYWORD} ;
terminal Only_kwd    /only/   lexer classes {KEYWORD} ;
terminal Hiding_kwd  /hiding/ lexer classes {KEYWORD} ;
terminal With_kwd    /with/   lexer classes {KEYWORD} ;
terminal As_kwd      /as/     lexer classes {KEYWORD} ;
terminal NonTerminal_kwd /nonterminal/ lexer classes {KEYWORD} ;
terminal Closed_kwd /closed/ lexer classes {KEYWORD} ;
terminal Close_kwd /close/ lexer classes {KEYWORD} ;
terminal Occurs_kwd /occurs/ lexer classes {KEYWORD} ;
terminal On_kwd /on/ lexer classes {KEYWORD} ;
terminal Forwards_kwd /forwards/ lexer classes {KEYWORD};
terminal To_kwd /to/ lexer classes {KEYWORD};
terminal Forwarding_kwd /forwarding/ lexer classes {KEYWORD};
terminal Forward_kwd /forward/ lexer classes {KEYWORD};
terminal Local_kwd /local/ lexer classes {KEYWORD} ;
terminal Abstract_kwd /abstract/ lexer classes {KEYWORD};
terminal Production_kwd /production/ lexer classes {KEYWORD};
terminal Grammar_kwd /grammar/  lexer classes {KEYWORD} ;
terminal If_kwd /if/ lexer classes {KEYWORD};
terminal Then_kwd /then/ lexer classes {KEYWORD};
terminal Else_kwd /else/ lexer classes {KEYWORD}, precedence = 4;
terminal Terminal_kwd /terminal/ lexer classes {KEYWORD};
terminal Integer_kwd /Integer/ lexer classes {KEYWORD} ;
terminal Float_kwd /Float/   lexer classes {KEYWORD} ;
terminal String_kwd /String/  lexer classes {KEYWORD} ;
terminal Boolean_kwd /Boolean/ lexer classes {KEYWORD} ;
terminal Exit_kwd /exit/ lexer classes {KEYWORD} ;

terminal CCEQ_t '::=' lexer classes {SEVEN};
terminal Semi_t ';' lexer classes {KEYWORD} ;
terminal Colon_t ':' lexer classes {KEYWORD} ;
terminal Equal_t '=' lexer classes {KEYWORD} ;
terminal Comma_t ',' lexer classes {KEYWORD}, precedence = 4 ;
terminal Dot_t '.' lexer classes {KEYWORD}, precedence = 25, association = left;
terminal LParen_t '(' lexer classes {KEYWORD}, precedence = 24;
terminal RParen_t ')' lexer classes {KEYWORD} ;
terminal LCurly_t '{' lexer classes {KEYWORD} ;
terminal RCurly_t '}' lexer classes {KEYWORD} ;
terminal HasType_t '::' lexer classes {SIX}, precedence = 14 ; -- TODO: I think this should be higher. 14? was 6.
terminal UnderScore_t '_' lexer classes {KEYWORD};
terminal Hash_t '#' lexer classes {KEYWORD}, precedence = 25, association = left;
terminal At_t '@' lexer classes {KEYWORD}, precedence = 25, association = left;
terminal And_t '&&' lexer classes {KEYWORD}, precedence = 6, association = left;
terminal Or_t '||' lexer classes {KEYWORD}, precedence = 5, association = left;
terminal Not_t '!' lexer classes {KEYWORD}, precedence = 7;
terminal GT_t '>' lexer classes {KEYWORD}, precedence = 9, association = left;
terminal LT_t '<' lexer classes {KEYWORD}, precedence = 9, association = left;
terminal GTEQ_t '>=' lexer classes {SIX} , precedence = 9, association = left;
terminal LTEQ_t '<=' lexer classes {SIX}, precedence = 9, association = left;
terminal EQEQ_t '==' lexer classes {SIX}, precedence = 9, association = left;
terminal NEQ_t '!=' lexer classes {SIX}, precedence = 9, association = left;
terminal Plus_t '+' lexer classes {KEYWORD}, precedence = 11, association = left;
terminal Minus_t '-' lexer classes {KEYWORD}, precedence = 11, association = left;
terminal Multiply_t '*' lexer classes {KEYWORD}, precedence = 12, association = left;
terminal PlusPlus_t '++' lexer classes {SIX}, precedence = 11, association = left;

ignore terminal comments /([\-][\-].*)/ ;
ignore terminal blockComments /\{\-([^\-]|\-+[^\}\-])*\-+\}/ ; --careful, now...
ignore terminal WhiteSpace /[\n\t\ ]+/ lexer classes {ZERO};

terminal Int_t /[0-9]+/ lexer classes {TWO};
terminal Id_t /[A-Za-z][A-Za-z0-9\_]*/ lexer classes {TWO};
terminal Float_t /[0-9]+[\.][0-9]+/ lexer classes {TWO};
terminal IdTick_t /[A-Za-z][A-Za-z0-9\_]*[\']/ lexer classes {TWO};
terminal IdTickTick_t /[A-Za-z][A-Za-z0-9\_]*[\'][\']/ lexer classes {TWO};
terminal String_t /[\"]([^\"\\]|[\\][\"]|[\\][\\]|[\\]n|[\\]r|[\\]t)*[\"]/ lexer classes {SIX};

terminal Divide_t '/' lexer classes {KEYWORD}, precedence = 12, association = left;
