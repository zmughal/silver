grammar silver:composed:idetest;

-- This grammar is a duplicate of Default, but...

import silver:host;
import silver:host:env;
import silver:translation:java;
import silver:driver;

--import silver:extension:doc;
import silver:analysis:warnings:defs;
import silver:analysis:warnings:exporting;

--hack for now
import silver:modification:impide;

parser svParse::Root {
  silver:host;

  silver:extension:convenience;

  silver:extension:list;
  silver:extension:easyterminal;

  silver:extension:deprecation;
  silver:extension:testing;
--  silver:extension:concreteSyntaxForTrees ;
  -- doc?

  silver:modification:let_fix;
  silver:modification:collection;
  silver:modification:patternmatching;
  silver:modification:autocopyattr;
  silver:modification:ffi;
  silver:modification:typedecl;
  silver:modification:copper;
  silver:modification:defaultattr;
  
  -- slight hacks, for the moment
  silver:modification:copper_mda;
  silver:modification:impide;
}

parser sviParse::IRoot {
  silver:host:env;

  silver:modification:collection:env_parser;
  silver:modification:autocopyattr:env_parser;
  silver:modification:ffi:env_parser;
  silver:modification:typedecl:env_parser;
  silver:modification:copper:env_parser;
  
  silver:extension:list:env_parser;
}

function main 
IOVal<Integer> ::= args::[String] ioin::IO
{
  return cmdLineRun(args, svParse, sviParse, ioin);
}

--- ... we're adding an ide declaration here

temp_imp_ide_dcl svParse ".sv" { 
  analyzer getErrors2;--a function whose signature must be "[String] ::= args::[IdeProperty] i::IO"
  property grammar_to_compile string;
  property grammar_to_include string;
};

function getErrors2
[String] ::= args::[IdeProperty] i::IO
{

  local sargs::[String] = getArgStrings(args) ++ getGrammarToCompile(args);

  local ru :: IOVal<[String]> = ideRun(sargs, svParse, sviParse, i);

  return ru.iovalue;
}

function getArgStrings
[String] ::= args::[IdeProperty]
{
  return
    if(null(args))
    then []
    else getArgString(head(args)) ++ getArgStrings(tail(args));
}

function getArgString
[String] ::= arg::IdeProperty
{
  return
    if arg.propName == "grammar_to_include"
    then ["-I", arg.propType]--FIXME: add new attribute propValue; now we just reuse propType (improperly)
    else [];
}

function getGrammarToCompile
[String] ::= args::[IdeProperty]
{
  return
    if(null(args))
    then []
    else if head(args).propName == "grammar_to_compile"
	    then [head(args).propType]--FIXME: add new attribute propValue; now we just reuse propType (improperly)
	    else getGrammarToCompile(tail(args));
}

function getErrors 
[String] ::= args::[String] i::IO
{

  local ru :: IOVal<[String]> = ideRun(args, svParse, sviParse, i);

  return ru.iovalue;
}

-- Yeah, that's a hack! :D

