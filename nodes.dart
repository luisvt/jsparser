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

#library("nodes");

interface NodeVisitor<T> {
  T visitProgram(Program program);

  T visitBlock(Block block);
  T visitExpressionStatement(ExpressionStatement expressionStatement);
  T visitInit(Init init);
  T visitNOP(NOP nop);
  T visitIf(If node);
  T visitFor(For loop);
  T visitForIn(ForIn loop);
  T visitWhile(While loop);
  T visitDo(Do loop);
  T visitContinue(Continue cont);
  T visitBreak(Break node);
  T visitReturn(Return node);
  T visitThrow(Throw node);
  T visitTry(Try node);
  T visitCatch(Catch node);
  T visitWith(With node);
  T visitSwitch(Switch node);
  T visitCase(Case node);
  T visitDefault(Default node);
  T visitFunctionDeclaration(FunctionDeclaration declaration);
  T visitLabeled(Labeled node);

  T visitVariableDeclarationList(VariableDeclarationList list);
  T visitSequence(Sequence sequence);
  T visitVassign(Vassign vassign);
  T visitAccsign(Accsign accsign);
  T visitVassignOp(VassignOp vassignOp);
  T visitAccsignOp(AccsignOp accsignOp);
  T visitConditional(Conditional cond);
  T visitNew(New node);
  T visitCall(Call call);
  T visitBinary(Binary binary);
  T visitUnary(Unary unary);
  T visitPostfix(Postfix postfix);

  T visitRef(Ref ref);
  T visitThis(This node);
  T visitDecl(Decl decl);
  T visitParam(Param param);
  T visitAccess(Access access);

  T visitNamedFunction(NamedFunction namedFunction);
  T visitFun(Fun fun);

  T visitBoolLiteral(BoolLiteral node);
  T visitStringLiteral(StringLiteral node);
  T visitNumberLiteral(NumberLiteral node);
  T visitNullLiteral(NullLiteral node);
  T visitUndefinedLiteral(UndefinedLiteral node);

  T visitArrayLiteral(ArrayLiteral node);
  T visitArrayElement(ArrayElement node);
  T visitObjectLiteral(ObjectLiteral node);
  T visitPropertyInit(PropertyInit node);
  T visitRegExpLiteral(RegExpLiteral node);
}

class BaseVisitor<T> implements NodeVisitor {
  T visitNode(Node node) {
    node.visitChildren(this);
    return null;
  }

  T visitProgram(Program node) => visitNode(node);

  T visitStatement(Statement node) => visitNode(node);
  T visitLoop(Loop node) => visitStatement(node);
  T visitInterruption(Statement node) => visitStatement(node);

  T visitBlock(Block node) => visitStatement(node);
  T visitExpressionStatement(ExpressionStatement node)
      => visitStatement(node);
  T visitNOP(NOP node) => visitStatement(node);
  T visitIf(If node) => visitStatement(node);
  T visitFor(For node) => visitLoop(node);
  T visitForIn(ForIn node) => visitLoop(node);
  T visitWhile(While node) => visitLoop(node);
  T visitDo(Do node) => visitLoop(node);
  T visitContinue(Continue node) => visitInterruption(node);
  T visitBreak(Break node) => visitInterruption(node);
  T visitReturn(Return node) => visitInterruption(node);
  T visitThrow(Throw node) => visitInterruption(node);
  T visitTry(Try node) => visitStatement(node);
  T visitWith(With node) => visitStatement(node);
  T visitSwitch(Switch node) => visitStatement(node);
  T visitFunctionDeclaration(FunctionDeclaration node)
      => visitStatement(node);
  T visitLabeled(Labeled node) => visitStatement(node);

  T visitCatch(Catch node) => visitNode(node);
  T visitInit(Init node) => visitNode(node);
  T visitCase(Case node) => visitNode(node);
  T visitDefault(Default node) => visitNode(node);

  T visitExpression(Expression node) => visitNode(node);
  T visitAssign(Assign node) => visitExpression(node);

  T visitVariableDeclarationList(VariableDeclarationList node)
      => visitExpression(node);
  T visitSequence(Sequence node) => visitExpression(node);
  T visitVassign(Vassign node) => visitAssign(node);
  T visitAccsign(Accsign node) => visitAssign(node);
  T visitVassignOp(VassignOp node) => visitVassign(node);
  T visitAccsignOp(AccsignOp node) => visitAccsign(node);
  T visitConditional(Conditional node) => visitExpression(node);
  T visitNew(New node) => visitExpression(node);
  T visitCall(Call node) => visitExpression(node);
  T visitBinary(Binary node) => visitCall(node);
  T visitUnary(Unary node) => visitCall(node);
  T visitPostfix(Postfix node) => visitCall(node);
  T visitAccess(Access node) => visitExpression(node);

  T visitRef(Ref node) => visitExpression(node);
  T visitDecl(Decl node) => visitRef(node);
  T visitParam(Param node) => visitDecl(node);
  T visitThis(This node) => visitParam(node);

  T visitNamedFunction(NamedFunction node) => visitExpression(node);
  T visitFun(Fun node) => visitExpression(node);

  T visitLiteral(Literal node) => visitExpression(node);

  T visitBoolLiteral(BoolLiteral node) => visitLiteral(node);
  T visitStringLiteral(StringLiteral node) => visitLiteral(node);
  T visitNumberLiteral(NumberLiteral node) => visitLiteral(node);
  T visitNullLiteral(NullLiteral node) => visitLiteral(node);
  T visitUndefinedLiteral(UndefinedLiteral node) => visitLiteral(node);

  T visitArrayLiteral(ArrayLiteral node) => visitExpression(node);
  T visitArrayElement(ArrayElement node) => visitNode(node);
  T visitObjectLiteral(ObjectLiteral node) => visitExpression(node);
  T visitPropertyInit(PropertyInit node) => visitNode(node);
  T visitRegExpLiteral(RegExpLiteral node) => visitExpression(node);
}

class Node implements Hashable {
  // I don't really like static state, but the alternatives seem even more
  // annoying.
  static int nodeCounter = 0;

  final int nodeId;
  Node() : nodeId = nodeCounter++ & 0x7FFFFFFF;

  abstract accept(NodeVisitor visitor);
  abstract void visitChildren(NodeVisitor visitor);
  int hashCode() => nodeId;
}

class Program extends Node {
  List<Statement> body;
  Program(this.body);

  accept(NodeVisitor visitor) => visitor.visitProgram(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in body) statement.accept(visitor);
  }
}

abstract class Statement extends Node {
}

class Block extends Statement {
  List<Statement> elements;
  Block(this.elements);

  accept(NodeVisitor visitor) => visitor.visitBlock(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in elements) statement.accept(visitor);
  }
}

class ExpressionStatement extends Statement {
  Expression expr;
  ExpressionStatement(this.expr);

  accept(NodeVisitor visitor) => visitor.visitExpressionStatement(this);
  void visitChildren(NodeVisitor visitor) { expr.accept(visitor); }
}

class NOP extends Statement {
  NOP();

  accept(NodeVisitor visitor) => visitor.visitNOP(this);
  void visitChildren(NodeVisitor visitor) {}
}

class If extends Statement {
  Node test;
  Node then;
  Node otherwise;
  If(this.test, this.then, this.otherwise);
  bool get hasElse() => otherwise is !NOP;

  accept(NodeVisitor visitor) => visitor.visitIf(this);
  void visitChildren(NodeVisitor visitor) {
    test.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }
}

abstract class Loop extends Statement {
  Statement body;
  Loop(this.body);
}

class For extends Loop {
  Expression init;
  Expression test;
  Expression incr;
  For(this.init, this.test, this.incr, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitFor(this);
  void visitChildren(NodeVisitor visitor) {
    if (init !== null) init.accept(visitor);
    if (test !== null) test.accept(visitor);
    if (incr !== null) incr.accept(visitor);
    body.accept(visitor);
  }
}

class ForIn extends Loop {
  Expression lhs;
  Expression obj;
  ForIn(this.lhs, this.obj, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitForIn(this);
  void visitChildren(NodeVisitor visitor) {
    lhs.accept(visitor);
    obj.accept(visitor);
    body.accept(visitor);
  }
}

class While extends Loop {
  Node test;
  While(this.test, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitWhile(this);
  void visitChildren(NodeVisitor visitor) {
    test.accept(visitor);
    body.accept(visitor);
  }
}

class Do extends Loop {
  Node test;
  Do(Statement body, this.test) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDo(this);
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    test.accept(visitor);
  }
}

class Continue extends Statement {
  String id;  // Can be null.
  Continue(this.id);

  accept(NodeVisitor visitor) => visitor.visitContinue(this);
  void visitChildren(NodeVisitor visitor) {}
}

class Break extends Statement {
  String id;  // Can be null.
  Break(this.id);

  accept(NodeVisitor visitor) => visitor.visitBreak(this);
  void visitChildren(NodeVisitor visitor) {}
}

class Return extends Statement {
  Expression expr;  // Can be null.
  Return(this.expr);

  accept(NodeVisitor visitor) => visitor.visitReturn(this);
  void visitChildren(NodeVisitor visitor) {
    expr.accept(visitor);
  }
}

class Throw extends Statement {
  Expression expr;
  Throw(this.expr);

  accept(NodeVisitor visitor) => visitor.visitThrow(this);
  void visitChildren(NodeVisitor visitor) {
    expr.accept(visitor);
  }
}

class Try extends Statement {
  Block body;
  Catch catchPart;
  Block finallyPart;
  Try(this.body, this.catchPart, this.finallyPart);

  accept(NodeVisitor visitor) => visitor.visitTry(this);
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    if (catchPart !== null) catchPart.accept(visitor);
    if (finallyPart !== null) finallyPart.accept(visitor);
  }
}

class Catch extends Node {
  Decl decl;
  Block body;
  Catch(this.decl, this.body);

  accept(NodeVisitor visitor) => visitor.visitCatch(this);
  void visitChildren(NodeVisitor visitor) {
    decl.accept(visitor);
    body.accept(visitor);
  }
}

class With extends Statement {
  Expression object;
  Statement body;
  With(this.object, this.body);

  accept(NodeVisitor visitor) => visitor.visitWith(this);
  void visitChildren(NodeVisitor visitor) {
    object.accept(visitor);
    body.accept(visitor);
  }
}

class Switch extends Statement {
  Expression key;
  List<SwitchClause> cases;
  Switch(this.key, this.cases);

  accept(NodeVisitor visitor) => visitor.visitSwitch(this);
  void visitChildren(NodeVisitor visitor) {
    key.accept(visitor);
    for (SwitchClause clause in cases) clause.accept(visitor);
  }
}

abstract class SwitchClause extends Node {
  Block body;
  SwitchClause(this.body);
}

class Case extends SwitchClause {
  Expression expr;
  Case(this.expr, Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitCase(this);
  void visitChildren(NodeVisitor visitor) {
    expr.accept(visitor);
    body.accept(visitor);
  }
}

class Default extends SwitchClause {
  Default(Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDefault(this);
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }
}

class FunctionDeclaration extends Statement {
  Decl id;
  Fun fun;
  FunctionDeclaration(this.id, this.fun);

  accept(NodeVisitor visitor) => visitor.visitFunctionDeclaration(this);
  void visitChildren(NodeVisitor visitor) {
    id.accept(visitor);
    fun.accept(visitor);
  }
}

class Labeled extends Statement {
  String id;
  Statement body;
  Labeled(this.id, this.body);

  accept(NodeVisitor visitor) => visitor.visitLabeled(this);
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }
}

abstract class Expression extends Node {
}

class VariableDeclarationList extends Expression {
  List<Init> declarations;
  VariableDeclarationList(this.declarations);

  accept(NodeVisitor visitor) => visitor.visitVariableDeclarationList(this);
  void visitChildren(NodeVisitor visitor) {
    for (Init init in declarations) init.accept(visitor);
  }
}

class Init extends Node {
  Decl decl;
  Expression value;  // May be null.
  Init(this.decl, this.value);

  accept(NodeVisitor visitor) => visitor.visitInit(this);
  void visitChildren(NodeVisitor visitor) {
    decl.accept(visitor);
    if (value !== null) value.accept(visitor);
  }
}

class Sequence extends Expression {
  List<Expression> expressions;
  Sequence(this.expressions);

  accept(NodeVisitor visitor) => visitor.visitSequence(this);
  void visitChildren(NodeVisitor visitor) {
    for (Expression expr in expressions) expr.accept(visitor);
  }
}

class Assign extends Expression {
  abstract Expression get lhs();
  Expression val;
  Assign(this.val);
}

class Vassign extends Assign {
  Ref lhs;
  Vassign(this.lhs, Expression val): super(val);

  accept(NodeVisitor visitor) => visitor.visitVassign(this);
  void visitChildren(NodeVisitor visitor) {
    lhs.accept(visitor);
    val.accept(visitor);
  }
}

class VassignOp extends Vassign {
  Ref op;
  VassignOp(Ref lhs, this.op, Expression val) : super(lhs, val);

  accept(NodeVisitor visitor) => visitor.visitVassignOp(this);
  void visitChildren(NodeVisitor visitor) {
    lhs.accept(visitor);
    op.accept(visitor);
    val.accept(visitor);
  }
}

class Accsign extends Assign {
  Access lhs;
  Accsign(this.lhs, Expression val): super(val);

  accept(NodeVisitor visitor) => visitor.visitAccsign(this);
  void visitChildren(NodeVisitor visitor) {
    lhs.accept(visitor);
    val.accept(visitor);
  }
}

class AccsignOp extends Accsign {
  Ref op;
  AccsignOp(Access lhs, this.op, Expression val) : super(lhs, val);

  accept(NodeVisitor visitor) => visitor.visitAccsignOp(this);
  void visitChildren(NodeVisitor visitor) {
    lhs.accept(visitor);
    op.accept(visitor);
    val.accept(visitor);
  }
}

class Conditional extends Expression {
  Expression test;
  Expression then;
  Expression otherwise;
  Conditional(this.test, this.then, this.otherwise);

  accept(NodeVisitor visitor) => visitor.visitConditional(this);
  void visitChildren(NodeVisitor visitor) {
    test.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }
}

class New extends Expression {
  Expression cls;
  List<Expression> arguments;
  New(this.cls, this.arguments);

  accept(NodeVisitor visitor) => visitor.visitNew(this);
  void visitChildren(NodeVisitor visitor) {
    cls.accept(visitor);
    for (Expression arg in arguments) arg.accept(visitor);
  }
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;
  Call(this.target, this.arguments);

  accept(NodeVisitor visitor) => visitor.visitCall(this);
  void visitChildren(NodeVisitor visitor) {
    target.accept(visitor);
    for (Expression arg in arguments) arg.accept(visitor);
  }
}

class Binary extends Call {
  Binary(Ref op, List<Expression> args) : super(op, args);

  accept(NodeVisitor visitor) => visitor.visitBinary(this);
  // Inherit visitChildren from [Call].
}

class Unary extends Call {
  Unary(Ref op, List<Expression> arg) : super(op, arg);

  accept(NodeVisitor visitor) => visitor.visitUnary(this);
  // Inherit visitChildren from [Call].
}

class Postfix extends Call {
  Postfix(Ref op, List<Expression> arg) : super(op, arg);

  accept(NodeVisitor visitor) => visitor.visitPostfix(this);
  // Inherit visitChildren from [Call].
}

class Ref extends Expression {
  final String id;
  final bool isOperator = false;
  final bool isUnaryOperator = false;

  Ref(this.id);
  Ref.operator(this.id) : isOperator = true;
  Ref.unaryOperator(this.id) : isOperator = true, isUnaryOperator = true;

  accept(NodeVisitor visitor) => visitor.visitRef(this);
  void visitChildren(NodeVisitor visitor) {}
}

class Decl extends Ref {
  Decl(String id) : super(id);

  accept(NodeVisitor visitor) => visitor.visitDecl(this);
  // Inherit visitChildren from [Ref].
}

class Param extends Decl {
  Param(String id) : super(id);

  accept(NodeVisitor visitor) => visitor.visitParam(this);
  // Inherit visitChildren from [Ref].
}

class This extends Param {
  This() : super("this");

  accept(NodeVisitor visitor) => visitor.visitThis(this);
  // Inherit visitChildren from [Ref].
}

class NamedFunction extends Expression {
  Decl id;
  Fun fun;
  NamedFunction(this.id, this.fun);

  accept(NodeVisitor visitor) => visitor.visitNamedFunction(this);
  void visitChildren(NodeVisitor visitor) {
    id.accept(visitor);
    fun.accept(visitor);
  }
}

class Fun extends Expression {
  List<Param> params;
  Block body;
  Fun(this.params, this.body);

  accept(NodeVisitor visitor) => visitor.visitFun(this);
  void visitChildren(NodeVisitor visitor) {
    for (Param param in params) param.accept(visitor);
    body.accept(visitor);
  }
}

class Access extends Expression {
  Expression receiver;
  Expression selector;
  Access(this.receiver, this.selector);

  accept(NodeVisitor visitor) => visitor.visitAccess(this);
  void visitChildren(NodeVisitor visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }
}

abstract class Literal extends Expression {
  void visitChildren(NodeVisitor visitor) {}
}

class BoolLiteral extends Literal {
  final bool value;
  BoolLiteral(this.value);

  accept(NodeVisitor visitor) => visitor.visitBoolLiteral(this);
  // [visitChildren] inherited from [Literal].
}

class UndefinedLiteral extends Literal {
  UndefinedLiteral();

  accept(NodeVisitor visitor) => visitor.visitUndefinedLiteral(this);
  // [visitChildren] inherited from [Literal].
}

class NullLiteral extends Literal {
  NullLiteral();

  accept(NodeVisitor visitor) => visitor.visitNullLiteral(this);
  // [visitChildren] inherited from [Literal].
}

class StringLiteral extends Literal {
  final String value;
  StringLiteral(this.value);

  accept(NodeVisitor visitor) => visitor.visitStringLiteral(this);
  // [visitChildren] inherited from [Literal].
}

class NumberLiteral extends Literal {
  final String value;
  NumberLiteral(this.value);

  accept(NodeVisitor visitor) => visitor.visitNumberLiteral(this);
  // [visitChildren] inherited from [Literal].
}

// Despite being called "Literal" the [ArrayLiteral] does not inherit from
// [Literal].
class ArrayLiteral extends Expression {
  int length;
  List<ArrayElement> elements;
  ArrayLiteral(this.length, this.elements);

  accept(NodeVisitor visitor) => visitor.visitArrayLiteral(this);
  void visitChildren(NodeVisitor visitor) {
    for (ArrayElement element in elements) element.accept(visitor);
  }
}

class ArrayElement extends Node {
  int index;
  Expression value;
  ArrayElement(this.index, this.value);

  accept(NodeVisitor visitor) => visitor.visitArrayElement(this);
  void visitChildren(NodeVisitor visitor) {
    value.accept(visitor);
  }
}

// Despite being called "Literal" the [ObjectLiteral] does not inherit from
// [Literal].
class ObjectLiteral extends Expression {
  List<PropertyInit> properties;
  ObjectLiteral(this.properties);

  accept(NodeVisitor visitor) => visitor.visitObjectLiteral(this);
  void visitChildren(NodeVisitor visitor) {
    for (PropertyInit init in properties) init.accept(visitor);
  }
}

class PropertyInit extends Node {
  Literal name;
  Expression value;
  PropertyInit(this.name, this.value);

  accept(NodeVisitor visitor) => visitor.visitPropertyInit(this);
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }
}

// Despite being called "Literal" the [RegExpLiteral] does not inherit from
// [Literal].
class RegExpLiteral extends Expression {
  /** Contains the pattern and the flags.*/
  String pattern;
  RegExpLiteral(this.pattern);

  accept(NodeVisitor visitor) => visitor.visitRegExpLiteral(this);
  void visitChildren(NodeVisitor visitor) {}
}
