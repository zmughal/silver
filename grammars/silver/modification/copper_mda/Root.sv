grammar silver:modification:copper_mda;

import silver:driver:util;

synthesized attribute mdaSpecs :: [MdaSpec] occurs on Root, AGDcls, AGDcl, RootSpec, GrammarPart, Grammar;

aspect production root
top::Root ::= gdcl::GrammarDcl ms::ModuleStmts ims::ImportStmts ags::AGDcls
{
  top.mdaSpecs = ags.mdaSpecs;
}

aspect production nilAGDcls
top::AGDcls ::=
{
  top.mdaSpecs = [];
}
aspect production consAGDcls
top::AGDcls ::= h::AGDcl t::AGDcls
{
  top.mdaSpecs = h.mdaSpecs ++ t.mdaSpecs;
}

aspect default production
top::AGDcl ::=
{
  top.mdaSpecs = [];
}
aspect production appendAGDcl
top::AGDcl ::= ag1::AGDcl ag2::AGDcl
{
  top.mdaSpecs = ag1.mdaSpecs ++ ag2.mdaSpecs;
}

aspect production grammarRootSpec
top::RootSpec ::= g::Grammar  _
{
  top.mdaSpecs = g.mdaSpecs;
}

aspect production grammarPart
top::GrammarPart ::= r::Root  fn::String
{
  top.mdaSpecs = r.mdaSpecs;
}

aspect production nilGrammar
top::Grammar ::=
{
  top.mdaSpecs = [];
}

aspect production consGrammar
top::Grammar ::= h::GrammarPart  t::Grammar
{
  top.mdaSpecs = h.mdaSpecs ++ t.mdaSpecs;
}

