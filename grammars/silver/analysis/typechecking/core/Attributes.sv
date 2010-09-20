grammar silver:analysis:typechecking:core;

synthesized attribute typeErrors :: [Decorated Message] with ++;
attribute typeErrors occurs on Root, AGDcls, AGDcl;
attribute typeErrors occurs on ProductionBody, ProductionStmts, ProductionStmt, ForwardInh, ForwardLHSExpr;
attribute typeErrors occurs on Expr, ForwardInhs;
attribute typeErrors occurs on ExprInhs, ExprInh, ExprLHSExpr;
attribute typeErrors occurs on Exprs;
