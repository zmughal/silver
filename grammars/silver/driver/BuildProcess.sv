grammar silver:driver;

imports silver:definition:core;
imports silver:definition:env;
imports silver:definition:env:env_parser;

imports silver:driver:util;
exports silver:driver:util;
imports silver:util;
imports silver:util:cmdargs;

inherited attribute svParser :: SVParser;
inherited attribute sviParser :: SVIParser;

type SVParser = (ParseResult<Root> ::= String String);
type SVIParser = (ParseResult<IRoot> ::= String String);

{--
 - Run the silver compiler, as if invoked from the command line.
 -}
function cmdLineRun
IOVal<Integer> ::= args::[String]  svParser::SVParser  sviParser::SVIParser  ioin::IO
{
  local argResult :: ParseResult<Decorated CmdArgs> = parseArgs(args);
  local a :: Decorated CmdArgs = argResult.parseTree;

  -- Let's locally set up and verify the environment
  local envSH :: IOVal<String> = envVar("SILVER_HOME", ioin);
  local envGP :: IOVal<String> = envVar("GRAMMAR_PATH", envSH.io);
  local envSG :: IOVal<String> = envVar("SILVER_GEN", envGP.io);
  
  local silverHome :: String =
    endWithSlash(head(a.silverHomeOption ++ [envSH.iovalue]));
  local silverGen :: String =
    endWithSlash(head(a.genLocation ++ (if envSG.iovalue == "" then [] else [envSG.iovalue]) ++ [silverHome ++ "generated/"]));
  local grammarPath :: [String] =
    map(endWithSlash, a.searchPath ++ [silverHome ++ "grammars/"] ++ explode(":", envGP.iovalue) ++ ["."]);
  local buildGrammar :: String = head(a.buildGrammar);

  local check :: IOVal<[String]> =
    checkEnvironment(a, silverHome, silverGen, grammarPath, buildGrammar, envSG.io);
  
  -- Compile grammars. There's some tricky circular program data flow here:
  local rootStream :: IOVal<[Maybe<RootSpec>]> =
    compileGrammars(svParser, sviParser, grammarPath, silverGen, buildGrammar :: grammarStream, true{-TODO a.doClean-}, check.io);
  
  local unit :: Compilation =
    compilation(foldr(consGrammars, nilGrammars(), foldr(consMaybe, [], rootStream.iovalue)),
      buildGrammar, silverHome, silverGen);
  unit.config = a;
  
  -- Note that this is used above. This outputs deps, and rootStream informs it.
  local grammarStream :: [String] =
    eatGrammars(1, [buildGrammar], rootStream.iovalue, unit.grammarList);
  
  -- TODO: Find "out of date" grammars, rebuild them.

  local actions :: IOVal<Integer> = runAll(sortUnits(unit.postOps), rootStream.io);

  return if a.displayVersion then ioval(print("Silver Version 0.3.6-dev\n", ioin), 0)
  else if !argResult.parseSuccess then ioval(print(argResult.parseErrors, ioin), 1)
  else if !null(check.iovalue) then ioval(print(implode("\n", check.iovalue), check.io), 1)
  else actions;
}

{--
 - Consumes a stream of parses, outputs a stream of new dependencies.
 - Typically used as a circular program with 'compileGrammars'
 -
 - @param n  Expected number of new inputs from rootStream
 - @param sofar  Set of grammars already seen, and should not be requested again
 - @param rootStream  Stream of found/not found info. Should not be used except to test presence
 - @param grammars  List of grammars *in the same order as 'just' appears in rootStream*
 - @return  A stream of new dependencies
 -}
function eatGrammars
[String] ::= n::Integer  sofar::[String]  rootStream::[Maybe<a>]  grammars::[Decorated RootSpec]
{
  local it :: Decorated RootSpec = head(grammars);
  
  local directDeps :: [String] = mentionedGrammars(it);
  
  local newDeps :: [String] = rem(directDeps, sofar);
  
  return
    if n == 0 then
      []
    else if !head(rootStream).isJust then
      eatGrammars(n-1, sofar, tail(rootStream), grammars)
    else
      newDeps ++ eatGrammars(n-1+length(newDeps), newDeps ++ sofar, tail(rootStream), tail(grammars));
}

-- TODO: look up a standard name for this, and put in std lib?
function consMaybe
[a] ::= h::Maybe<a>  t::[a]
{
  return if h.isJust then h.fromJust :: t else t;
}


{--
 - Ensures a string ends with a forward slash. Safe to use if it already has one.
 -}
function endWithSlash
String ::= s::String
{
  return if endsWith("/", s) then s else s ++ "/";
}


