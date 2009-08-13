grammar silver:definition:concrete_syntax;
import silver:definition:core;
import silver:definition:env;

aspect production defaultNonterminalDcl
top::AGDcl ::=  id::Name
{
  top.parserDcls = [];
  top.nonTerminalDcls = [nonTerminalSpec(fName)];  
  top.terminalDcls = [];
  top.ruleDcls = [];
}

aspect production closeNonterminalDcl
top::AGDcl ::= 'close' 'nonterminal' q::QName ';'
{
  top.parserDcls = [];
  top.nonTerminalDcls = [nonTerminalSpec(fName)];  
  top.terminalDcls = [];
  top.ruleDcls = [];
}
