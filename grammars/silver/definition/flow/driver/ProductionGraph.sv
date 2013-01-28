grammar silver:definition:flow:driver;

import silver:util only rem, contains;
import silver:definition:type only isDecorable;

nonterminal ProductionGraph with flowTypes, stitchedGraph, prod, lhsNt, transitiveClosure, edgeMap, cullSuspect;

inherited attribute flowTypes :: EnvTree<Pair<String String>>;
{--
 - Given a set of flow types, stitches those edges into the graph for
 - all stitch points (i.e. children, locals, forward)
 -}
synthesized attribute stitchedGraph :: ProductionGraph;
{--
 - Just compute the transitive closure of the edge set
 -}
synthesized attribute transitiveClosure :: ProductionGraph;
{--
 - Edge mapper
 -}
synthesized attribute edgeMap :: ([FlowVertex] ::= FlowVertex);

synthesized attribute cullSuspect :: ProductionGraph;

synthesized attribute prod::String;
synthesized attribute lhsNt::String;

{--
 - An object for representing a production's flow graph.
 - Should ALWAYS be a transitive closure over the edges for 'vertexes'.
 -
 - @param prod  The full name of this production
 - @param lhsNt  The full name of the nonterminal this production constructs
 - @param vertexes  The vertexes to keep a transitive closure over
 - @param edges  The edges within this production
 - @param edgeGraph  Invariant: map version of 'edges'
 - @param suspectEdges  Edges that are not permitted to affect their OWN flow types (but perhaps some unknown other flowtypes)
 - @param stitchPoints  Places where current flow types need grafting to this graph to yield a full flow graph
 -
 - @see constructProductionGraph for how to go about getting an object of this type
 -}
abstract production productionGraph
top::ProductionGraph ::=
  prod::String
  lhsNt::String
  vertexes::[FlowVertex]
  edges::[Pair<FlowVertex FlowVertex>]
  edgeGraph::EnvTree<FlowVertex>
  suspectEdges::[Pair<FlowVertex FlowVertex>]
  stitchPoints::[Pair<(FlowVertex ::= String) String>]
{
  top.prod = prod;
  top.lhsNt = lhsNt;
  
  top.stitchedGraph = 
    let newEdges :: [Pair<FlowVertex FlowVertex>] =
          filter(edgeIsNew(_, edgeGraph),
            foldr(append, [], map(stitchEdgesFor(_, top.flowTypes), stitchPoints)))
    in let newVertexes :: [FlowVertex] = nubBy(flowVertexEq, map(getFst, newEdges) ++ vertexes)
    in let repaired :: Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> =
             repairClosure(newEdges, newVertexes, edges, edgeGraph)
    in if null(newEdges) then top else
         productionGraph(prod, lhsNt, newVertexes, repaired.fst, repaired.snd, suspectEdges, stitchPoints)
    end end end;
  
  top.transitiveClosure =
    let transitiveClosure :: Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> =
          transitiveClose(vertexes, edges, edgeGraph)
    in
      productionGraph(prod, lhsNt, vertexes, transitiveClosure.fst, transitiveClosure.snd, suspectEdges, stitchPoints) end;
    
  top.edgeMap = searchGraphEnv(_, edgeGraph);
  
  top.cullSuspect = 
    -- TODO: this potentially introduces the same edge twice?
    let newEdges :: [Pair<FlowVertex FlowVertex>] =
          foldr(append, [], 
            map(isSuspectEdgeAdmissible(_, edgeGraph, searchEnvTree(lhsNt, top.flowTypes)), suspectEdges))
    in let newVertexes :: [FlowVertex] = nubBy(flowVertexEq, map(getFst, newEdges) ++ vertexes)
    in let repaired :: Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> =
             repairClosure(newEdges, newVertexes, edges, edgeGraph)
    in if null(newEdges) then top else
         productionGraph(prod, lhsNt, newVertexes, repaired.fst, repaired.snd, suspectEdges, stitchPoints)
    end end end;
}

{--
 - Produces a ProductionGraph in some special way. Fixes up implicit equations,
 - figures out stitch points, and so forth.
 -
 - 1. All HOA synthesized attributes have a dep on their equation. 
 - 1b. Same for forwarding.
 - 2. All synthesized attributes missing equations have dep on their corresponding fwd.
 - 2b. OR use their default if not forwarding and it exists.
 - 3. All inherited attributes not supplied to forward have copies.
 - 4. All autocopy attributes not supplied to childred have copies.
 -
 - @param prod  The full name of the production
 - @param defs  The set of defs from prodGraphContribs
 - @param flowEnv  A full flow environment
 - @param realEnv  A full real environment
 - @return A fixed up graph.
 -}
function constructProductionGraph
ProductionGraph ::= prod::String  defs::[FlowDef]  flowEnv::Decorated FlowEnv  realEnv::Decorated Env
{
  -- The dcl for this production
  local dcl :: DclInfo = head(getValueDclAll(prod, realEnv));
  -- The LHS nonterminal full name
  local nt :: NtName = dcl.namedSignature.outputElement.typerep.typeName;
  -- All attributes occurrences
  local attrs :: Pair<[DclInfo] [DclInfo]> = partition(isOccursSynthesized(_, realEnv), getAttrsOn(nt, realEnv));
  -- Just synthesized attributes.
  local syns :: [String] = map((.attrOccurring), attrs.fst);
  -- Just inherited.
  local inhs :: [String] = map((.attrOccurring), attrs.snd);
  -- Autocopy.
  local autos :: [String] = filter(isAutocopy(_, realEnv), inhs);
  
  -- Normal edges!
  local normalEdges :: [Pair<FlowVertex FlowVertex>] =
    foldr(append, [], map((.flowEdges), defs));
  
  -- Insert implicit equations.
  local fixedEdges :: [Pair<FlowVertex FlowVertex>] =
    normalEdges ++
    (if null(lookupFwd(prod, flowEnv))
     then addDefEqs(prod, nt, syns, flowEnv)
     else addFwdEqs(syns) ++ addFwdSynEqs(prod, synsBySuspicion.fst, flowEnv) ++ addFwdInhEqs(prod, inhs, flowEnv)) ++
    fixupAllHOAs(defs, flowEnv, realEnv) ++
    addAllAutoCopyEqs(prod, dcl.namedSignature.inputElements, autos, flowEnv, realEnv);
  
  local vertexes :: [FlowVertex] =
    nubBy(flowVertexEq, map(getFst, fixedEdges));
  
  -- (safe, suspect)
  local synsBySuspicion :: Pair<[String] [String]> =
    partition(contains(_, getNonSuspectAttrsForProd(prod, flowEnv)), syns);
  
  -- No implicit equations here, just keep track.
  local suspectEdges :: [Pair<FlowVertex FlowVertex>] =
    foldr(append, [], map((.suspectFlowEdges), defs)) ++
    if null(lookupFwd(prod, flowEnv)) then [] else addFwdSynEqs(prod, synsBySuspicion.snd, flowEnv);

  -- RHS and locals and forward.
  local stitchPoints :: [Pair<(FlowVertex ::= String) String>] =
    rhsStitchPoints(dcl.namedSignature.inputElements) ++
    localStitchPoints(nt, defs);

  return productionGraph(prod, nt, vertexes, fixedEdges, directBuildTree(map(makeGraphEnv, fixedEdges)), suspectEdges, stitchPoints).transitiveClosure;
}

---- Begin helpers for fixing up graphs ----------------------------------------

{--
 - Introduces 'hoa.syn -> hoaeq' edges.
 - These are ALWAYS included in standard edges.
 -}
function fixupAllHOAs
[Pair<FlowVertex FlowVertex>] ::= d::[FlowDef] flowEnv::Decorated FlowEnv realEnv::Decorated Env
{
  return case d of
  | [] -> []
  | localEq(_, fN, "", deps) :: rest -> fixupAllHOAs(rest, flowEnv, realEnv)
  | localEq(_, fN, tN, deps) :: rest -> 
      addHOASynDeps(map((.attrOccurring), filter(isOccursSynthesized(_, realEnv), getAttrsOn(tN, realEnv))), fN) ++
        fixupAllHOAs(rest, flowEnv, realEnv)
  | _ :: rest -> fixupAllHOAs(rest, flowEnv, realEnv)
  end;
}
-- Helper for above
function addHOASynDeps
[Pair<FlowVertex FlowVertex>] ::= synattrs::[String]  fName::String
{
  return if null(synattrs) then []
  else pair(localVertex(fName, head(synattrs)), localEqVertex(fName)) :: addHOASynDeps(tail(synattrs), fName);
}
{--
 - Introduces implicit 'forward.syn -> forward' equations.
 -}
function addFwdEqs
[Pair<FlowVertex FlowVertex>] ::= syns::[String]
{
  return if null(syns) then []
  else 
    pair(forwardVertex(head(syns)), forwardEqVertex()) :: addFwdEqs(tail(syns));
}
{--
 - Introduces implicit 'lhs.syn -> forward.syn' equations.
 - TODO: BUG: these should be suspect only when they're introduced externally!!!
 -}
function addFwdSynEqs
[Pair<FlowVertex FlowVertex>] ::= prod::ProdName syns::[String] flowEnv::Decorated FlowEnv
{
  return if null(syns) then []
  else (if null(lookupSyn(prod, head(syns), flowEnv))
    then [pair(lhsSynVertex(head(syns)), forwardVertex(head(syns)))] else []) ++
    addFwdSynEqs(prod, tail(syns), flowEnv);
}
{--
 - Introduces implicit 'forward.inh = lhs.inh' equations.
 - Inherited equations are never suspect.
 -}
function addFwdInhEqs
[Pair<FlowVertex FlowVertex>] ::= prod::ProdName inhs::[String] flowEnv::Decorated FlowEnv
{
  return if null(inhs) then []
  else (if null(lookupFwdInh(prod, head(inhs), flowEnv)) then [pair(forwardVertex(head(inhs)), lhsInhVertex(head(inhs)))] else []) ++
    addFwdInhEqs(prod, tail(inhs), flowEnv);
}
{--
 - Introduces default equations deps. Realistically, should be empty, always.
 -}
function addDefEqs
[Pair<FlowVertex FlowVertex>] ::= prod::ProdName nt::NtName syns::[String] flowEnv :: Decorated FlowEnv
{
  return if null(syns) then []
  else (if null(lookupSyn(prod, head(syns), flowEnv)) 
        then let x :: [FlowDef] = lookupDef(nt, head(syns), flowEnv)
              in if null(x) then [] else head(x).flowEdges 
             end
        else []) ++
    addDefEqs(prod, nt, tail(syns), flowEnv);
}
{--
 - Introduces 'rhs.inh = lhs.inh' wherever not present.
 - Inherited equations are never suspect.
 -}
function addAllAutoCopyEqs
[Pair<FlowVertex FlowVertex>] ::= prod::ProdName sigNames::[NamedSignatureElement] inhs::[String] flowEnv::Decorated FlowEnv realEnv::Decorated Env
{
  return if null(sigNames) then []
  else addAutocopyEqs(prod, head(sigNames), inhs, flowEnv, realEnv) ++ addAllAutoCopyEqs(prod, tail(sigNames), inhs, flowEnv, realEnv);
}
-- Helper for above.
function addAutocopyEqs
[Pair<FlowVertex FlowVertex>] ::= prod::ProdName sigName::NamedSignatureElement inhs::[String] flowEnv::Decorated FlowEnv realEnv::Decorated Env
{
  return if null(inhs) then []
  else (if null(lookupInh(prod, sigName.elementName, head(inhs), flowEnv))  -- no equation
        && !null(getOccursDcl(head(inhs), sigName.typerep.typeName, realEnv)) -- and it occurs on this type
        then [pair(rhsVertex(sigName.elementName, head(inhs)), lhsInhVertex(head(inhs)))]
        else []) ++
    addAutocopyEqs(prod, sigName, tail(inhs), flowEnv, realEnv);
}

---- End helpers for fixing up graphs ------------------------------------------

---- Begin helpers for figuring out stitch points ------------------------------

function localStitchPoints
[Pair<(FlowVertex ::= String) String>] ::= nt::NtName  d::[FlowDef]
{
  return case d of
  | [] -> []
  -- We add the forward stitch point here, too!
  | fwdEq(_, _, _) :: rest -> pair(forwardVertex, nt) :: localStitchPoints(nt, rest)
  -- Ignore locals that aren't nonterminal types!
  | localEq(_, fN, "", deps) :: rest -> localStitchPoints(nt, rest)
  -- Add locals that are nonterminal types.
  | localEq(_, fN, tN, deps) :: rest -> pair(localVertex(fN, _), tN) :: localStitchPoints(nt, rest)
  -- Ignore all other flow def info
  | _ :: rest -> localStitchPoints(nt, rest)
  end;
}
function rhsStitchPoints
[Pair<(FlowVertex ::= String) String>] ::= rhs::[NamedSignatureElement]
{
  return if null(rhs) then []
  -- We want only NONTERMINAL stitch points!
  else if head(rhs).typerep.isDecorable
       then pair(rhsVertex(head(rhs).elementName, _), head(rhs).typerep.typeName) :: rhsStitchPoints(tail(rhs))
       else rhsStitchPoints(tail(rhs));
}

---- End helpers for figuring our stitch points --------------------------------

---- Begin helpers for graph stitching -----------------------------------------
function dualApply
Pair<b b> ::= f::(b ::= a)  x::Pair<a a>
{
  return pair(f(x.fst), f(x.snd));
}
{--
 - Turns, for example, "(rhs1, Expr) * FlowTypes -> {(rhs1.pp, rhs1.indent), ...}"
 -
 - @param spec A "stitch point." fst is a vertex set in the graph, snd is the nonterminal type for that vertex
 - @param ntEnv is a flow type set to use
 - @return A set of edges to add to a production graph, for this stich-point, given the flow type.
 -}
function stitchEdgesFor
[Pair<FlowVertex FlowVertex>] ::= spec::Pair<(FlowVertex ::= String) NtName>  ntEnv::EnvTree<Pair<String String>>
{
  return map(dualApply(spec.fst, _), searchEnvTree(spec.snd, ntEnv));
}
function edgeIsNew
Boolean ::= edge::Pair<FlowVertex FlowVertex>  e::EnvTree<FlowVertex>
{
  return !containsBy(flowVertexEq, edge.snd, searchGraphEnv(edge.fst, e));
}
---- End helpers for graph stitching -------------------------------------------

---- Begin transitive closure computation --------------------------------------
function transitiveClose
Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> ::=
  vertexes::[FlowVertex]
  edges::[Pair<FlowVertex FlowVertex>]
  currentGraph::EnvTree<FlowVertex>
{
  return transitiveCloseThese(vertexes, edges, currentGraph);
}
function transitiveCloseThese
Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> ::=
  vertexes::[FlowVertex]
  edges::[Pair<FlowVertex FlowVertex>]
  currentGraph::EnvTree<FlowVertex>
{
  local allNew :: [Pair<FlowVertex FlowVertex>] =
    foldr(append, [], map(transitiveCloseIteration(_, currentGraph), vertexes));
  
  return pair(allNew ++ edges, extendEnv(allNew, currentGraph));
}
function transitiveCloseIteration
[Pair<FlowVertex FlowVertex>] ::= vertex::FlowVertex  edges::EnvTree<FlowVertex>
{
  local currentEdges :: [FlowVertex] = searchGraphEnv(vertex, edges);
  
  local newEdges :: [FlowVertex] = transitiveCloseSet(currentEdges, [vertex], vertex :: currentEdges, edges);
  
  return map(pair(vertex, _), newEdges);
}
{--
 - @param need  A set of vertexes to examine the dependencies of
 - @param seen  A set of already processed vertexes
 - @param old   A set of edges that already exist
 - @param graph The graph
 - @return A set of NEW vertexes that should be introduced!
 -}
function transitiveCloseSet
[FlowVertex] ::= need::[FlowVertex]  seen::[FlowVertex]  old::[FlowVertex]  graph::EnvTree<FlowVertex>
{
  local expanded :: [FlowVertex] = searchGraphEnv(head(need), graph);

  -- If there's nothing needed, then no new edges are introduced.
  return if null(need) then []
  -- If this vertex has already been processed, discard it.
  else if containsBy(flowVertexEq, head(need), seen) then transitiveCloseSet(tail(need), seen, old, graph)
  -- If this vertex is already in the dependencies, discard. But we must consider those dependencies, still...
  else if containsBy(flowVertexEq, head(need), old) then transitiveCloseSet(expanded ++ tail(need), head(need) :: seen, old, graph)
  -- The vertex is new! Emit the new edge, and continue... (note this is the same continue as above ^^)
  else head(need) :: transitiveCloseSet(expanded ++ tail(need), head(need) :: seen, old, graph);
}
function getFst
a ::= v::Pair<a b>
{ return v.fst; }
function makeGraphEnv
Pair<String FlowVertex> ::= p::Pair<FlowVertex FlowVertex>
{
  return pair(p.fst.dotName, p.snd);
}
function searchGraphEnv
[FlowVertex] ::= v::FlowVertex e::EnvTree<FlowVertex>
{
  return searchEnvTree(v.dotName, e);
}
function extendEnv
EnvTree<FlowVertex> ::= newEdges::[Pair<FlowVertex FlowVertex>]  currentGraph::EnvTree<FlowVertex>
{
  return rtm:add(map(makeGraphEnv, newEdges), currentGraph);
}
---- End transitive Closure computation ----------------------------------------

---- Begin transitive closure repair function ----------------------------------
function repairClosure
Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> ::=
  newEdges::[Pair<FlowVertex FlowVertex>]
  vertexes::[FlowVertex]
  currentEdges::[Pair<FlowVertex FlowVertex>]
  currentGraph::EnvTree<FlowVertex>
{
  local repairIter :: Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> = 
    repairClosureEdge(head(newEdges), vertexes, currentEdges, currentGraph);

  return if null(newEdges) then pair(currentEdges, currentGraph)
  else repairClosure(tail(newEdges), vertexes, repairIter.fst, repairIter.snd);
}
function repairClosureEdge
Pair<[Pair<FlowVertex FlowVertex>] EnvTree<FlowVertex>> ::=
  newEdge::Pair<FlowVertex FlowVertex>
  vertexes::[FlowVertex]
  currentEdges::[Pair<FlowVertex FlowVertex>]
  currentGraph::EnvTree<FlowVertex>
{
  local allNewEdges :: [Pair<FlowVertex FlowVertex>] =
    foldr(append, [], map(repairClosureVertex(newEdge, _, currentEdges, currentGraph), vertexes));
  
  return pair(allNewEdges ++ currentEdges, extendEnv(allNewEdges, currentGraph));
}
{--
 - @param newEdge  An edge to consider
 - @param vertex  A vertex to consider
 - @return A list of NEW edges to introduce to the graph, to repair the
 -  existing transitive closure, adding this edge.
 -}
function repairClosureVertex
[Pair<FlowVertex FlowVertex>] ::=
  newEdge::Pair<FlowVertex FlowVertex>
  vertex::FlowVertex
  currentEdges::[Pair<FlowVertex FlowVertex>]
  currentGraph::EnvTree<FlowVertex>
{
  -- Input graph (edges, graph) is already transitively closed.
  -- We're focused on JUST vertex
  
  local deps :: [FlowVertex] = searchGraphEnv(vertex, currentGraph);
  local newDeps :: [FlowVertex] = searchGraphEnv(newEdge.snd, currentGraph);
  
  -- If the edge source not this vertex, nor in the existing deps, do nothing
  return if !containsBy(flowVertexEq, newEdge.fst, vertex :: deps) then []
  -- From here on out, the target deps should be added to this vertex.
  -- If the edge target is already in the deps, do nothing. Old news.
  else if containsBy(flowVertexEq, newEdge.snd, deps) then []
  -- Otherwise, remove all source deps from target deps, and introduce these edges.
  else map(pair(vertex, _), removeAllBy(flowVertexEq, deps, newEdge.snd :: newDeps));
}
---- End transitive closure repair function ------------------------------------



---- Begin Suspect edge handling -----------------------------------------------

{--
 - This function finds edges that should be introduced from a suspect edge.
 -
 - Suspect edges themselves can never be introduced, because the interaction of
 - introducing two or more suspect edges can be undesirable.  (a,b) might be
 - introduced, followed by (b,c). But (b,c) might have prevented (a,b) from
 - appearing!
 -
 - Instead we introduce their ultimate dependencies of interest:
 - If (a,b) is introduced, we actually introduce (a, x) for x: an inherited
 - attribute that a does not already depend upon that is in a's flow type.
 - This way, after (b,c)'s edges are admitted, we come back to (a,b) and do not
 - admit the extra edges c introduced for a.
 -
 - A note on this being applied "in parallel:" it's okay not to update 'ft' and 'graph'
 - after each edge is introduced, as this is conservative: it just means we'll
 - potentially introduce an edge next iteration.
 - The reason is that each edge is TO an lhsInh, which never gets edges from it.
 - So once valid that edge is valid, it is always valid. No additional edges or
 - flow type updates will change that.
 -
 - @param edge  A suspect edge. INVARIANT: edge.fst is always a syn or fwd.
 -              (or rather, can always be looked up in the flow type.)
 - @param graph  The current graph
 - @param ft  The current flow types for the nonterminal this graph belongs to.
 - @return  Edges to introduce. INVARIANT: .fst is always edge.fst, .snd is
 -          always an lhsInhVertex.
 -}
function isSuspectEdgeAdmissible
[Pair<FlowVertex FlowVertex>] ::= edge::Pair<FlowVertex FlowVertex>  graph::EnvTree<FlowVertex>  ft::[Pair<String String>]
{
  -- The existing dependencies of the edge's source vertex
  local sourceDeps :: [String] = foldr(collectInhs, [], searchGraphEnv(edge.fst, graph));
  -- Ditto for the target vertex
  local targetDeps :: [String] = foldr(collectInhs, [], searchGraphEnv(edge.snd, graph));
  -- The current flow type of the edge's source vertex (which is always a thing in the flow type)
  local currentDeps :: [String] = lookupAllBy(stringEq, edge.fst.flowTypeName, ft);
  
  -- Those dependencies in the target that are NOT in the source. i.e. potentially new dependencies!
  local targetNotSource :: [String] = rem(targetDeps, sourceDeps);
  -- ONLY those that ARE in current. i.e. dependencies that do not expand the flow type of this source vertex.
  local validDeps :: [FlowVertex] = map(lhsInhVertex, filter(contains(_, currentDeps), targetNotSource));
  
  return if null(currentDeps) then [] -- just a quick optimization.
  else map(pair(edge.fst, _), validDeps);
}
