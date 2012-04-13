grammar silver:translation:java:core;

aspect production globalValueDclConcrete
top::AGDcl ::= 'global' id::Name '::' t::Type '=' e::Expr ';'
{
  -- TODO: would be nice to use more specific types
  top.initValues := "\tpublic static final common.Thunk<Object> " ++ id.name 
      ++ " = " ++ wrapThunkText("common.TopNode.singleton", e.translation, "Object") ++ ";\n";
}
