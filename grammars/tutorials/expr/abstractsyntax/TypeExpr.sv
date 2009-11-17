grammar edu:umn:cs:melt:tutorial:expr:abstractsyntax ;

import edu:umn:cs:melt:tutorial:expr:terminals ;

nonterminal TypeExpr ;

attribute typerep occurs on TypeExpr ;

attribute pp occurs on TypeExpr ;

abstract production intTypeExpr
te::TypeExpr ::= i::Int_t
{
 te.pp = i.lexeme ;
 te.typerep = intType();
}

abstract production booleanTypeExpr
te::TypeExpr ::= b::Boolean_t
{
 te.pp = b.lexeme ;
 te.typerep = booleanType();
}



