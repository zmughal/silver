grammar silver:analysis:binding:driver;
import silver:analysis:binding:command;
import silver:driver;

import silver:definition:core;
import silver:definition:env;
import core;

aspect production run
top::RunUnit ::= iIn::IO args::String
{
  postOps <- if a.noBindingChecking then [] else [printAllBindingErrors(grammars)]; 
}

abstract production printAllBindingErrors
top::Unit ::= specs::[Decorated RootSpec]
{
  forwards to printAllBindingErrorsHelp(specs)
	with {
		ioIn = print("Checking Binding Errors.\n", top.ioIn);
	};
}

abstract production printAllBindingErrorsHelp
top::Unit ::= specs::[Decorated RootSpec]
{
  local attribute es :: [Decorated Message];
  es = head(specs).errors;

  local attribute i :: IO;
  i = if null(es) then top.ioIn else print("Binding Errors for : " ++ head(specs).impliedName ++ "\n" ++ foldMessages(es) ++ "\n\n", top.ioIn);

  local attribute recurse :: Unit;
  recurse = printAllBindingErrorsHelp(tail(specs));
  recurse.ioIn = i;

  top.io = if null(specs) then top.ioIn else recurse.io;

  top.code = if null(specs) || (null(es) && recurse.code == 0)
	     then 0 
	     else -1;

  top.order = 0;
}