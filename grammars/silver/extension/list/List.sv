grammar silver:extension:list;
import silver:definition:core;
import silver:definition:env;
import silver:definition:type;
import silver:definition:type:syntax;

import silver:analysis:typechecking:core;

terminal LSqr_t '[' lexer classes {KEYWORD};
terminal RSqr_t ']' lexer classes {KEYWORD};

-- The TYPE --------------------------------------------------------------------
concrete production listType
top::Type ::= '[' te::Type ']'
{
  top.typerep = listTypeExp(te.typerep);

  forwards to refType('Decorated', 
                   nominalType(qNameUpperId(terminal(IdUpper_t, "core:List")),
                                    botlSome('<', typeListSingle(te), '>')));
}

-- The expressions -------------------------------------------------------------

concrete production emptyList
top::Expr ::= '[' ']'
{
  top.pp = "[]";
  top.location = loc(top.file, $1.line, $1.column);

  forwards to mkFunctionInvocation(baseExpr(qName(top.location, "core:nil")), []);
}

-- TODO: BUG: '::' is HasType_t.  We probably want to have a different
-- terminal here, with different precedence!

concrete production consListOp
top::Expr ::= h::Expr '::' t::Expr
{
  top.pp = "(" ++ h.pp ++ " :: " ++ t.pp ++ ")" ;
  top.location = loc(top.file, $2.line, $2.column);
  
  h.downSubst = top.downSubst; t.downSubst = top.downSubst; -- TODO BUG: don't know what this is needed... pp apparently??
  
  forwards to mkFunctionInvocation(baseExpr(qName(top.location, "core:cons")), [h, t]);
}

concrete production fullList
top::Expr ::= '[' es::Exprs ']'
{ 
  top.pp = "[ " ++ es.pp ++ " ]";
  
  es.downSubst = top.downSubst; -- TODO again, pretty printing garbage.

  forwards to es.listtrans;
}

synthesized attribute listtrans :: Expr occurs on Exprs;

aspect production exprsEmpty
top::Exprs ::=
{
  top.listtrans = emptyList('[',']');
}

aspect production exprsSingle
top::Exprs ::= e::Expr
{
  top.listtrans = mkFunctionInvocation(baseExpr(qName(e.location, "core:cons")), [e, emptyList('[',']')]);
}

aspect production exprsCons
top::Exprs ::= e1::Expr c::Comma_t e2::Exprs
{
  top.listtrans = mkFunctionInvocation(baseExpr(qName(e1.location, "core:cons")), [e1, e2.listtrans]);
}

-- Overloaded operators --------------------------------------------------------

abstract production listPlusPlus
top::Expr ::= e1::Decorated Expr e2::Decorated Expr
{
  forwards to mkFunctionInvocationDecorated(baseExpr(qName(e1.location, "core:append")), [e1,e2]);
}
abstract production listLengthBouncer
top::Expr ::= e::Decorated Expr
{
  forwards to mkFunctionInvocationDecorated(baseExpr(qName(e.location, "core:listLength")), [e]);
}

