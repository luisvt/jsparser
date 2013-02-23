// Copyright 2012, Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library resolver;
import "nodes.dart";
import "var.dart";
import "printer.dart";

class ResolverPrinter extends Printer {
  final Map<Node, Var> resolution;
  final Map<Var, int> varIds = new Map<Var, int>();
  int idCounter = 0;

  ResolverPrinter(this.resolution);

  outResolution(VariableReference node) {
    Var resolvedVar = resolution[node];
    if (resolvedVar != null) {
      int varId = varIds.putIfAbsent(resolvedVar, () => idCounter++);
      out("<$varId>");
    }
  }

  visitVariableUse(VariableUse node) {
    super.visitVariableUse(node);
    outResolution(node);
  }

  visitParameter(Parameter node) {
    super.visitParameter(node);
    outResolution(node);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    outResolution(node);
  }
}


Map<Node, Var> resolve(Program program) {
  Collector collector = new Collector();
  collector.collect(program);
  Resolver resolver =
      new Resolver(collector.declaredVars, collector.scopesContainingEval);
  resolver.visitProgram(program);
  return resolver.resolution;
}

class Collector extends BaseVisitor {
  /** Node is either [Program], [NamedFunction], [Fun] or [Try]. */
  final Map<Node, Map<String, Var>> declaredVars;
  final Set<Node> scopesContainingEval;

  Node currentScope;
  Map<String, Var> declaredVarsInCurrentScope;

  bool get isGlobal => currentScope is Program;

  Collector()
      : declaredVars = new Map<Node, Map<String, Var>>(),
        scopesContainingEval = new Set<Node>();

  void collect(Program program) {
    program.accept(this);
  }

  visitScope(Node node, void doInsideScope()) {
    Node oldScope = currentScope;
    Map oldDeclaredVars = declaredVarsInCurrentScope;
    currentScope = node;
    declaredVarsInCurrentScope = new Map<String, Var>();
    declaredVars[node] = declaredVarsInCurrentScope;
    doInsideScope();
    node.visitChildren(this);
    declaredVarsInCurrentScope = oldDeclaredVars;
    currentScope = oldScope;
  }

  void addThis() {
    declaredVarsInCurrentScope["this"] = new Var("this", isParam: true);
  }

  void addOperators() {
    for (Operator op in OPERATORS) {
      declaredVarsInCurrentScope[op.id] = op;
    }
  }

  void addArgumentsObject() {
    declaredVarsInCurrentScope["arguments"] =
        new Var("arguments", isParam: true);
  }

  visitProgram(Program node) {
    visitScope(node, () {
      addThis();
      addOperators();
      node.visitChildren(this);
    });
  }

  visitNamedFunction(NamedFunction node) {
    visitScope(node, () {
      node.visitChildren(this);
    });
  }

  visitFun(Fun node) {
    visitScope(node, () {
      addThis();
      addArgumentsObject();
      node.visitChildren(this);
    });
  }

  visitWith(With node) {
    // Add empty map. This will be filled with interceptors in a later
    // traversal.
    Map<String, Var> withMap = new Map<String, Var>();
    declaredVars[node] = withMap;
    node.visitChildren(this);
  }

  visitCatch(Catch node) {
    // A catch is only a partial scope. It introduces the exception into its
    // body, but 'var's that are defined inside the body are defined for the
    // whole function. This is even true, if the 'var' uses the same name as
    // the one of the exception.
    Map<String, Var> catchMap = new Map<String, Var>();
    String exceptionId = node.declaration.name;
    catchMap[exceptionId] = new Var(exceptionId, isParam: true);
    declaredVars[node] = catchMap;
    node.body.accept(this);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    String id = node.name;
    declaredVarsInCurrentScope[id] = new Var(id, isGlobal: isGlobal);
  }

  visitParameter(Parameter node) {
    String id = node.name;
    declaredVarsInCurrentScope[id] = new Var(id, isParam: true);
  }

  // This method is not collecting variables, but just marking all scopes that
  // contain 'eval' calls.
  visitCall(Call node) {
    if (node.target is VariableUse) {
      VariableUse target = node.target;
      if (target.name == "eval") scopesContainingEval.add(currentScope);
    }
    node.visitChildren(this);
  }
}

class Resolver extends BaseVisitor {
  final Map<Node, Map<String, Var>> declaredVars;
  final Set<Node> scopesContainingEval;

  final Map<Node, Var> resolution;

  final List<Node> scopes;
  final List<Map<String, Var>> scopesVars;

  Resolver(this.declaredVars, this.scopesContainingEval)
      : resolution = new Map<Node, Var>(),
        scopes = <Node>[],
        scopesVars = <Map<String, Var>>[];

  visitScope(Node node) {
    scopes.add(node);
    scopesVars.add(declaredVars[node]);
    node.visitChildren(this);
    scopesVars.length--;
    scopes.length--;
  }

  visitProgram(Program node) => visitScope(node);
  visitNamedFunction(NamedFunction node) => visitScope(node);
  visitFun(Fun node) => visitScope(node);
  visitWith(With node) => visitScope(node);
  visitCatch(Catch node) => visitScope(node);

  visitVariableReference(VariableReference node) {
    Var resolved = resolve(node.name, scopes.length - 1);
    resolution[node] = resolved;
  }

  Var resolve(String id, int scopeIndex) {
    Map<String, Var> vars = scopesVars[scopeIndex];
    Var v = vars[id];
    if (v != null) return v;
    Node scope = scopes[scopeIndex];

    if (scope is Program) {
      Var implicit = new Var(id, isGlobal: true, isImplicit: true);
      vars[id] = implicit;
      return implicit;
    }
    if (scope is With || scopesContainingEval.contains(scope)) {
      Var intercepted = resolve(id, scopeIndex - 1);
      Var interceptor = new Interceptor(id, intercepted, scope);
      vars[id] = interceptor;
      return interceptor;
    }
    return resolve(id, scopeIndex - 1);
  }
}
