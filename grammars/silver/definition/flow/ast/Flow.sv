grammar silver:definition:flow:ast;

import silver:definition:env only quoteString;

nonterminal FlowDefs with synTreeContribs, defTreeContribs, fwdTreeContribs, unparses, prodTreeContribs;
nonterminal FlowDef with synTreeContribs, defTreeContribs, fwdTreeContribs, unparses, prodTreeContribs;

synthesized attribute synTreeContribs :: [Pair<String FlowDef>];
synthesized attribute defTreeContribs :: [Pair<String FlowDef>];
synthesized attribute fwdTreeContribs :: [Pair<String FlowDef>];
synthesized attribute prodTreeContribs :: [Pair<String FlowDef>];
synthesized attribute unparses :: [String];

abstract production consFlow
top::FlowDefs ::= h::FlowDef  t::FlowDefs
{
  top.synTreeContribs = h.synTreeContribs ++ t.synTreeContribs;
  top.defTreeContribs = h.defTreeContribs ++ t.defTreeContribs;
  top.fwdTreeContribs = h.fwdTreeContribs ++ t.fwdTreeContribs;
  top.prodTreeContribs = h.prodTreeContribs ++ t.prodTreeContribs;
  top.unparses = h.unparses ++ t.unparses;
}

abstract production nilFlow
top::FlowDefs ::=
{
  top.synTreeContribs = [];
  top.defTreeContribs = [];
  top.fwdTreeContribs = [];
  top.prodTreeContribs = [];
  top.unparses = [];
}

-- At the time of writing, this is one giant work in progress.
-- Currently, all we're going to report is whether a synthesized
-- equation EXISTS or whether a production forwards at all.
-- This will be implemented in such a way that it returns the
-- FlowDef, but presently that has no special information.

aspect default production
top::FlowDef ::=
{
  top.synTreeContribs = [];
  top.defTreeContribs = [];
  top.fwdTreeContribs = [];
  top.prodTreeContribs = [];
}

{--
 - Declaration of a NON-FORWARDING production. Exists to allow lookups of productions
 - from nonterminal name.
 -
 - @param nt  The full name of the nonterminal it constructs
 - @param prod  The full name of the production
 -}
abstract production prodFlowDef
top::FlowDef ::= nt::String  prod::String
{
  top.prodTreeContribs = [pair(nt, top)];
  top.unparses = ["prod(" ++ quoteString(nt) ++ ", " ++ quoteString(prod) ++ ")"];
}

{--
 - The definition of a synthesized attribute in a production.
 -
 - @param prod  the full name of the production
 - @param attr  the full name of the attribute
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE POSSIBLE
 -}
abstract production synEq
top::FlowDef ::= prod::String  attr::String  --  deps::[FlowVertex]
{
  top.synTreeContribs = [pair(crossnames(prod, attr), top)];
  top.unparses = ["syn(" ++ quoteString(prod) ++ ", " ++ quoteString(attr) ++ ")"];
}

{--
 - The definition of a inherited attribute for a signature element in a production.
 -
 - @param prod  the full name of the production
 - @param sigName  the name of the RHS element
 - @param attr  the full name of the attribute
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE POSSIBLE
 -}
abstract production inhEq
top::FlowDef ::= prod::String  sigName::String  attr::String  deps::[FlowVertex]
{
  top.unparses = error("TODO"); -- TODO
}

{--
 - The definition of a default equation for a synthesized attribute on a nonterminal.
 -
 - @param nt  the full name of the *nonterminal*
 - @param attr  the full name of the attribute
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE POSSIBLE
 -}
abstract production defEq
top::FlowDef ::= nt::String  attr::String  --  deps::[FlowVertex]
{
  top.defTreeContribs = [pair(crossnames(nt, attr), top)];
  top.unparses = ["def(" ++ quoteString(nt) ++ ", " ++ quoteString(attr) ++ ")"];
}

{--
 - The definition of the forward of a production.
 -
 - @param prod  the full name of the production
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE *NOT* repeat *NOT* POSSIBLE
 -}
abstract production fwdEq
top::FlowDef ::= prod::String  --  deps::[FlowVertex]
{
  top.fwdTreeContribs = [pair(prod, top)];
  top.unparses = ["fwd(" ++ quoteString(prod) ++ ")"];
}

{--
 - The definition of an inherited attribute on the forward
 -
 - @param prod  the full name of the production
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE POSSIBLE
 -}
abstract production fwdInhEq
top::FlowDef ::= prod::String  deps::[FlowVertex]
{
  top.fwdTreeContribs = [pair(prod, top)];
  top.unparses = ["fwd(" ++ quoteString(prod) ++ ")"];
}

{--
 - The definition of a local or production attribute's equation.
 - MAY not be a nonterminal type!
 -
 - @param prod  the full name of the production
 - @param fName  the name of the local/production attribute
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE POSSIBLE
 -}
abstract production localEq
top::FlowDef ::= prod::String  fName::String  deps::[FlowVertex]
{
  top.unparses = error("TODO"); -- TODO
}

{--
 - The definition of an inherited attribute for a local attribute.
 -
 - @param prod  the full name of the production
 - @param fName  the name of the local/production attribute
 - @param attr  the full name of the attribute
 - @param deps  the dependencies of this equation on other flow graph elements
 - CONTRIBUTIONS ARE POSSIBLE
 -}
abstract production localInhEq
top::FlowDef ::= prod::String  fName::String  attr::String  deps::[FlowVertex]
{
  top.unparses = error("TODO"); -- TODO
}

--

function crossnames
String ::= a::String b::String
{
  return a ++ " @ " ++ b;
}

--

{--
 - Data structure representing vertices in the flow graph within a single production.
 -}
nonterminal FlowVertex;

{--
 - A vertex representing an attribute on the nonterminal being constructed by this production.
 -
 - @param attrName  the full name of an attribute on the lhs.
 -}
abstract production lhsVertex
top::FlowVertex ::= attrName::String
{
}

{--
 - A vertex representing an attribute on an element of the signature RHS.
 -
 - @param sigName  the name given to a signature nonterminal.
 - @param attrName  the full name of an attribute on that signature element.
 -}
abstract production rhsVertex
top::FlowVertex ::= sigName::String  attrName::String
{
}

{--
 - A vertex representing a local equation. i.e. forward, local attribute, production
 - attribute, etc.  Note that this may be defined for MORE than just those with
 - nonterminal type!! (e.g. local foo :: String  will appear!)
 -
 - @param fName  the full name of the NTA/FWD being defined
 -}
abstract production localEqVertex
top::FlowVertex ::= fName::String
{
}

{--
 - A vertex representing an attribute on a local equation. i.e. forward, local
 - attribute, production attribute, etc.  Note this this implies the equation
 - above IS a nonterminal type!!
 -
 - @param fName  the full name of the NTA/FWD
 - @param attrName  the fulle name of the attribute on that element
 -}
abstract production localVertex
top::FlowVertex ::= fName::String  attrName::String
{
}

