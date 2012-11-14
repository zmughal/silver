grammar silver:definition:core;

nonterminal Name with config, grammarName, file, location, pp, name;
nonterminal NameTick with config, grammarName, file, location, pp, name;
nonterminal NameTickTick with config, grammarName, file, location, pp, name;

{--
 - An identifier's (possibly qualified) name.
 -}
synthesized attribute name :: String;

concrete production nameIdLower
top::Name ::= id::IdLower_t
{
  top.name = id.lexeme;
  top.pp = id.lexeme;
  top.location = loc(top.file, id.line, id.column);
}
concrete production nameIdUpper
top::Name ::= id::IdUpper_t
{
  top.name = id.lexeme;
  top.pp = id.lexeme;
  top.location = loc(top.file, id.line, id.column);
}

concrete production nameIdTick
top::NameTick ::= id::IdTick_t
{
  top.pp = id.lexeme;
  top.location = loc(top.file, id.line, id.column);
  top.name = substring(0, length(id.lexeme) -1, id.lexeme);
}

concrete production nameIdTickTick
top::NameTickTick ::= id::IdTickTick_t
{
  top.pp = id.lexeme;
  top.location = loc(top.file, id.line, id.column);
  top.name = substring(0, length(id.lexeme) -2, id.lexeme);
}
