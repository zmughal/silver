grammar silver:analysis:typechecking:core;

aspect production lengthFunction
top::Expr ::= 'length' '(' e::Expr ')'
{
  e.downSubst = top.downSubst;
  top.upSubst = e.upSubst;
}
aspect production stringLength
top::Expr ::= e::Decorated Expr
{
  top.typeErrors := e.typeErrors;      
}

aspect production unknownLength
top::Expr ::= e::Decorated Expr
{
  top.typeErrors <- [err(e.location, "operand to 'length(..)' is not compatible.")];
  top.typeErrors := e.typeErrors;      
}

aspect production errorFunction
top::Expr ::= 'error' '(' e::Expr ')'
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;

  top.typeErrors := e.typeErrors;
  
  e.downSubst = top.downSubst;
  errCheck1.downSubst = e.upSubst;
  top.upSubst = errCheck1.upSubst;
  
  errCheck1 = check(e.typerep, stringTypeExp());
  top.typeErrors <-
       if errCheck1.typeerror
       then [err(e.location, "Parameter to error must be a String. Instead it is " ++ errCheck1.leftpp)]
       else [];
}

aspect production toIntFunction
top::Expr ::= 'toInt' '(' e1::Expr ')'
{
  top.typeErrors := e1.typeErrors;
  
  e1.downSubst = top.downSubst;
  top.upSubst = e1.upSubst;
  
  top.typeErrors <-
       if performSubstitution(e1.typerep, top.finalSubst).instanceConvertible
       then []
       else [err(top.location, "Operand to toInt must be concrete types String Integer, or Float.  Instead it is of type " ++ prettyType(performSubstitution(e1.typerep, top.finalSubst)))];
}

aspect production toFloatFunction
top::Expr ::= 'toFloat' '(' e1::Expr ')'
{
  top.typeErrors := e1.typeErrors;
  
  e1.downSubst = top.downSubst;
  top.upSubst = e1.upSubst;
  
  top.typeErrors <-
       if performSubstitution(e1.typerep, top.finalSubst).instanceConvertible
       then []
       else [err(top.location, "Operand to toFloat must be concrete types String Integer, or Float.  Instead it is of type " ++ prettyType(performSubstitution(e1.typerep, top.finalSubst)))];
}

aspect production toStringFunction
top::Expr ::= 'toString' '(' e1::Expr ')'
{
  top.typeErrors := e1.typeErrors;
  
  e1.downSubst = top.downSubst;
  top.upSubst = e1.upSubst;
  
  top.typeErrors <-
       if performSubstitution(e1.typerep, top.finalSubst).instanceConvertible
       then []
       else [err(top.location, "Operand to toString must be concrete types String Integer, or Float.  Instead it is of type " ++ prettyType(performSubstitution(e1.typerep, top.finalSubst)))];
}

aspect production newFunction
top::Expr ::= 'new' '(' e1::Expr ')'
{
  top.typeErrors := e1.typeErrors;
  
  e1.downSubst = top.downSubst;
  top.upSubst = e1.upSubst;
  
  top.typeErrors <-
       if performSubstitution(e1.typerep, top.finalSubst).isDecorated
       then []
       else [err(top.location, "Operand to new must be a decorated nonterminal.  Instead it is of type " ++ prettyType(performSubstitution(e1.typerep, top.finalSubst)))];
}

aspect production terminalFunction
top::Expr ::= 'terminal' '(' t::Type ',' e1::Expr ')'
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;

  top.typeErrors := e1.typeErrors;
  
  e1.downSubst = top.downSubst;
  errCheck1.downSubst = e1.upSubst;
  top.upSubst = errCheck1.upSubst;
  
  errCheck1 = check(e1.typerep, stringTypeExp());
  top.typeErrors <-
       if errCheck1.typeerror
       then [err(top.location, "Second operand to 'terminal(type,lexeme)' must be a String, instead it is " ++ errCheck1.leftpp)]
       else [];
  
  top.typeErrors <-
        if (t.typerep.isTerminal) 
        then []
        else [err(top.location, "First operand to 'terminal(type,lexeme)' must be a Terminal, instead it is " ++ prettyType(t.typerep))];
}

aspect production terminalFunctionLineCol
top::Expr ::= 'terminal' '(' t::Type ',' e1::Expr ',' e2::Expr ',' e3::Expr ')'
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;
  local attribute errCheck2 :: TypeCheck; errCheck2.finalSubst = top.finalSubst;
  local attribute errCheck3 :: TypeCheck; errCheck3.finalSubst = top.finalSubst;

  top.typeErrors := e1.typeErrors ++ e2.typeErrors ++ e3.typeErrors;
  
  e1.downSubst = top.downSubst;
  errCheck1.downSubst = e1.upSubst;
  errCheck2.downSubst = errCheck1.upSubst;
  errCheck3.downSubst = errCheck2.upSubst;
  top.upSubst = errCheck3.upSubst;
  
  errCheck1 = check(e1.typerep, stringTypeExp());
  errCheck2 = check(e2.typerep, intTypeExp());
  errCheck3 = check(e3.typerep, intTypeExp());
  top.typeErrors <-
       if errCheck1.typeerror
       then [err(e1.location, "Second operand to 'terminal(type,lexeme,line,column)' must be a String, instead it is " ++ errCheck1.leftpp)]
       else [];
  top.typeErrors <-
       if errCheck2.typeerror
       then [err(e2.location, "Third operand to 'terminal(type,lexeme,line,column)' must be an Integer, instead it is " ++ errCheck2.leftpp)]
       else [];
  top.typeErrors <-
       if errCheck3.typeerror
       then [err(e3.location, "Fourth operand to 'terminal(type,lexeme,line,column)' must be an Integer, instead it is " ++ errCheck3.leftpp)]
       else [];
  
  top.typeErrors <-
        if (t.typerep.isTerminal) 
        then []
        else [err(top.location, "First operand to 'terminal(type,lexeme,line,column)' must be a Terminal, instead it is " ++ prettyType(t.typerep))];
}

aspect production terminalFunctionInherited
top::Expr ::= 'terminal' '(' t::Type ',' e1::Expr ',' e2::Expr ')'
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;

  top.typeErrors := e1.typeErrors;
  
  e1.downSubst = top.downSubst;
  e2.downSubst = e1.upSubst;
  errCheck1.downSubst = e2.upSubst;
  top.upSubst = errCheck1.upSubst;
  
  errCheck1 = check(e1.typerep, stringTypeExp());
  top.typeErrors <-
       if errCheck1.typeerror
       then [err(top.location, "Second operand to 'terminal(type,lexeme,terminal)' must be a String, instead it is " ++ errCheck1.leftpp)]
       else [];
  
  top.typeErrors <-
        if (t.typerep.isTerminal) 
        then []
        else [err(top.location, "First operand to 'terminal(type,lexeme,terminal)' must be a Terminal, instead it is " ++ prettyType(t.typerep))];

  top.typeErrors <-
        if (e2.typerep.isTerminal) -- UG TODO
        then []
        else [err(top.location, "Third operand to 'terminal(type,lexeme,terminal)' must be a Terminal, instead it is " ++ prettyType(e2.typerep))];
}
