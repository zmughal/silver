grammar silver:modification:collection:java;
import silver:modification:collection;

import silver:util;

import silver:definition:core;
import silver:definition:env;

import silver:translation:java:core;
import silver:translation:java:type;
import silver:extension:list;


{-

  The initialization order is a bit scattered.
  
  For locals, the common.CollectionAttribute object is created by the 'prod attr foo...' declaration.
  For inherited attributes, CA object is created when base is defined.
  For synthesized attributes, CA object is created conditionally at EVERY := or <- decl.

  Why the above difference?  Something to do with initialization order that I forgot.
  The problem was for synthesized only.  Something about trying to add to the CA object before it was created.

  Synthesized and inherited get a CA class file.
  Production are anonymous as they are never repeated.
  

-}

synthesized attribute frontTrans :: String;
synthesized attribute midTrans :: String;
synthesized attribute endTrans :: String;
inherited attribute inType :: Decorated TypeRep;

attribute frontTrans, midTrans, endTrans, inType occurs on Operation;

aspect production nameOperation
top::Operation ::= s::String {
  top.frontTrans = "new " ++ makeClassName(s) ++"(";
  top.midTrans = ", ";
  top.endTrans = ")";
}

aspect production plusPlusOperation
top::Operation ::= {
  top.frontTrans = if top.inType.isString then "" else if top.inType.isList then "new common.AppendCell(" else error("Not Implemented");
  top.midTrans = if top.inType.isString then ".append(" else if top.inType.isList then ", " else error("Not Implemented");
  top.endTrans = if top.inType.isString then ")" else if top.inType.isList then ")" else error("Not Implemented");
}

--- Declarations

aspect production collectionAttributeDclProd
top::ProductionStmt ::= 'production' 'attribute' a::Name '::' te::Type 'with' q::NameOrBOperator ';'
{
  local attribute className :: String;
  className = makeClassName(top.signature.fullName);

  local attribute o :: Operation;
  o = q.operation;
  o.inType = te.typerep;

  top.setupInh := 
        "\t\t" ++ className ++ ".localAttributes.put(\"" ++ fName ++ "\", new common.CollectionAttribute(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++ 
        "\t\t\t\t" ++ te.typerep.transType ++ " result = (" ++ te.typerep.transType ++ ")this.getBase().eval(context);\n" ++ 
        "\t\t\t\tfor(int i = 0; i < this.getPieces().size(); i++){\n" ++ 
        "\t\t\t\t\tresult = " ++ o.frontTrans ++ "result" ++ o.midTrans ++ "(" ++ te.typerep.transType ++ ")this.getPieces().get(i).eval(context)" ++ o.endTrans ++ ";\n" ++ 
        "\t\t\t\t}\n" ++ 
        "\t\t\t\treturn result;\n" ++ 
        "\t\t\t}\n" ++ 
        "\t\t});\n" ++ 
        if !te.typerep.isNonTerminal then  "" else
                 "\t\t" ++ className ++ ".inheritedAttributes.put(\"" ++ fName ++ "\", " ++ "new java.util.TreeMap<String, common.Lazy>());\n";

  top.translation = "";
}

aspect production collectionAttributeDclSyn
top::AGDcl ::= 'synthesized' 'attribute' a::Name '::' te::Type 'with' q::NameOrBOperator ';'
{
  local attribute className :: String;
  className = "CA" ++ a.name;

  local attribute o :: Operation;
  o = q.operation;
  o.inType = te.typerep;

  top.javaClasses = [[className,
                
"package " ++ makeName(top.grammarName) ++ ";\n\n" ++

"public class " ++ className ++ " extends common.CollectionAttribute {\n\n" ++

"\tpublic " ++ className ++ "() {\n" ++
"\t\tsuper(\"" ++ fName ++ "\");\n" ++
"\t}\n\n" ++

"\tpublic Object eval(common.DecoratedNode context) {\n" ++ 
"\t\t" ++ te.typerep.transType ++ " result = (" ++ te.typerep.transType ++ ")this.getBase().eval(context);\n" ++ 
"\t\tfor(int i = 0; i < this.getPieces().size(); i++){\n" ++ 
"\t\t\tresult = " ++ o.frontTrans ++ "result" ++ o.midTrans ++ "(" ++ te.typerep.transType ++ ")this.getPieces().get(i).eval(context)" ++ o.endTrans ++ ";\n" ++ 
"\t\t}\n" ++ 
"\t\treturn result;\n" ++ 
"\t}\n\n" ++ 


"}\n"]];
}

aspect production collectionAttributeDclInh
top::AGDcl ::= 'inherited' 'attribute' a::Name '::' te::Type 'with' q::NameOrBOperator ';'
{
  local attribute className :: String;
  className = "CA" ++ a.name;

  local attribute o :: Operation;
  o = q.operation;
  o.inType = te.typerep;

  top.javaClasses = [[className,
                
"package " ++ makeName(top.grammarName) ++ ";\n\n" ++

"public class " ++ className ++ " extends common.CollectionAttribute {\n\n" ++

"\tpublic " ++ className ++ "() {\n" ++
"\t\tsuper(\"" ++ fName ++ "\");\n" ++
"\t}\n\n" ++

"\tpublic Object eval(common.DecoratedNode context) {\n" ++ 
"\t\t" ++ te.typerep.transType ++ " result = (" ++ te.typerep.transType ++ ")this.getBase().eval(context);\n" ++ 
"\t\tfor(int i = 0; i < this.getPieces().size(); i++){\n" ++ 
"\t\t\tresult = " ++ o.frontTrans ++ "result" ++ o.midTrans ++ "(" ++ te.typerep.transType ++ ")this.getPieces().get(i).eval(context)" ++ o.endTrans ++ ";\n" ++ 
"\t\t}\n" ++ 
"\t\treturn result;\n" ++ 
"\t}\n\n" ++ 


"}\n"]];
}

--- Use semantics translation

aspect production baseCollectionValueDef
top::ProductionStmt ::= val::Decorated QName '=' e::Expr
{
  local attribute className :: String;
  className = makeClassName(top.signature.fullName);

  top.setupInh := "";

  top.translation =
        "\t\t// " ++ val.pp ++ " := " ++ e.pp ++ "\n" ++
        "\t\t((common.CollectionAttribute)" ++ className ++ ".localAttributes.get(\"" ++ val.lookupValue.fullName ++ "\")).setBase(new common.Lazy(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++
        "\t\t\t\treturn " ++ e.translation ++ ";\n" ++
        "\t\t\t}\n" ++ 
        "\t\t});\n";
}
aspect production appendCollectionValueDef
top::ProductionStmt ::= val::Decorated QName '=' e::Expr
{
  local attribute className :: String;
  className = makeClassName(top.signature.fullName);

  top.setupInh := "";

  top.translation = 
        "\t\t// " ++ val.pp ++ " <- " ++ e.pp ++ "\n" ++
        "\t\t((common.CollectionAttribute)" ++ className ++ ".localAttributes.get(\"" ++ val.lookupValue.fullName ++ "\")).addPiece(new common.Lazy(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++
        "\t\t\t\treturn " ++ e.translation ++ ";\n" ++
        "\t\t\t}\n" ++ 
        "\t\t});\n";
}

aspect production synBaseColAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' {- := -} e::Expr
{
  top.setupInh := "";

  top.translation =
        "\t\t// " ++ dl.pp ++ "." ++ attr.pp ++ " := " ++ e.pp ++ "\n" ++
        "\t\tif((" ++ dl.translation ++ ".get(\"" ++ attr.lookupAttribute.fullName ++ "\")) == null)\n" ++
        "\t\t\t" ++ dl.translation ++ ".put(\"" ++ attr.lookupAttribute.fullName ++ "\",  new " ++ makeCAClassName(attr.lookupAttribute.fullName) ++"());\n" ++
        "\t\t((common.CollectionAttribute)" ++ dl.translation ++ ".get(\"" ++ attr.lookupAttribute.fullName ++ "\")).setBase(new common.Lazy(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++
        "\t\t\t\treturn " ++ e.translation ++ ";\n" ++
        "\t\t\t}\n" ++ 
        "\t\t});\n";
}
aspect production synAppendColAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' {- <- -} e::Expr
{
  top.setupInh := "";

  top.translation = 
	"\t\t// " ++ dl.pp ++ "." ++ attr.pp ++ " <- " ++ e.pp ++ "\n" ++
        "\t\tif(" ++ dl.translation ++ ".get(\"" ++ attr.lookupAttribute.fullName ++ "\") == null)\n" ++
        "\t\t\t" ++ dl.translation ++ ".put(\"" ++ attr.lookupAttribute.fullName ++ "\",  new " ++ makeCAClassName(attr.lookupAttribute.fullName) ++"());\n" ++
        "\t\t((common.CollectionAttribute)" ++ dl.translation ++ ".get(\"" ++ attr.lookupAttribute.fullName ++ "\")).addPiece(new common.Lazy(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++
        "\t\t\t\treturn " ++ e.translation ++ ";\n" ++
        "\t\t\t}\n" ++ 
        "\t\t});\n";
}
aspect production inhBaseColAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' {- := -} e::Expr
{
  top.setupInh := 
        "\t\t" ++ dl.translation ++ ".put(\"" ++ attr.lookupAttribute.fullName ++ "\",  new " ++ makeCAClassName(attr.lookupAttribute.fullName) ++"());\n";


  top.translation =
        "\t\t// " ++ dl.pp ++ "." ++ attr.pp ++ " := " ++ e.pp ++ "\n" ++
        "\t\t((common.CollectionAttribute)" ++ dl.translation ++ ".get(\"" ++ attr.lookupAttribute.fullName ++ "\")).setBase(new common.Lazy(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++
        "\t\t\t\treturn " ++ e.translation ++ ";\n" ++
        "\t\t\t}\n" ++ 
        "\t\t});\n";
}
aspect production inhAppendColAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' {- <- -} e::Expr
{
  top.setupInh := "";

  top.translation = 
	"\t\t// " ++ dl.pp ++ "." ++ attr.pp ++ " <- " ++ e.pp ++ "\n" ++
        "\t\t((common.CollectionAttribute)" ++ dl.translation ++".get(\"" ++ attr.lookupAttribute.fullName ++ "\")).addPiece(new common.Lazy(){\n" ++ 
        "\t\t\tpublic Object eval(common.DecoratedNode context) {\n" ++
        "\t\t\t\treturn " ++ e.translation ++ ";\n" ++
        "\t\t\t}\n" ++ 
        "\t\t});\n";
}


function makeCAClassName
String ::= s::String {
  return makeClassNameHelp(split(":", s), "CA");
}

