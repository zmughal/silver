grammar silver:translation:java:core;

aspect production globalValueDclConcrete
top::AGDcl ::= 'global' id::Name '::' t::Type '=' e::Expr ';'
{
  top.setupInh := "";
  top.initProd := "";
  top.initValues := "\tpublic static final common.RealThunk " ++ id.name ++ " = new common.RealThunk(common.TopNode.singleton, new common.Lazy(){public Object eval(common.DecoratedNode context) {return " ++ e.translation ++ ";}});\n";
  top.postInit := "";

  top.javaClasses = [];
}