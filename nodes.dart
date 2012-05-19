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
  T visitVariableDeclarationList(VariableDeclarationList list);
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
}

class Node {
  const Node();

  abstract accept(NodeVisitor visitor);
}

class Program extends Node {
  List<Statement> body;
  Program(this.body);

  accept(NodeVisitor visitor) => visitor.visitProgram(this);
}

abstract class Statement extends Node {
  const Statement();
}

class Block extends Statement {
  List<Statement> elements;
  Block(this.elements);

  accept(NodeVisitor visitor) => visitor.visitBlock(this);
}

class VariableDeclarationList extends Statement {
  List<Init> declarations;
  VariableDeclarationList(this.declarations);

  accept(NodeVisitor visitor) => visitor.visitVariableDeclarationList(this);
}

class ExpressionStatement extends Statement {
  Expression expr;
  ExpressionStatement(this.expr);

  accept(NodeVisitor visitor) => visitor.visitExpressionStatement(this);
}

class Init extends Node {
  Decl decl;
  Expression value;  // May be null.
  Init(this.decl, this.value);

  accept(NodeVisitor visitor) => visitor.visitInit(this);
}

class NOP extends Statement {
  const NOP();

  accept(NodeVisitor visitor) => visitor.visitNOP(this);
}

class If extends Statement {
  Node test;
  Node then;
  Node otherwise;
  If(this.test, this.then, this.otherwise);
  bool get hasElse() => otherwise is !NOP;

  accept(NodeVisitor visitor) => visitor.visitIf(this);
}

abstract class Loop extends Statement {
  Statement body;
  Loop(this.body);
}

class For extends Loop {
  Statement init;
  Expression test;
  Expression incr;
  For(this.init, this.test, this.incr, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitFor(this);
}

class ForIn extends Loop {
  Node lhs;
  Expression obj;
  ForIn(this.lhs, this.obj, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitForIn(this);
}

class While extends Loop {
  Node test;
  While(this.test, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitWhile(this);
}

class Do extends Loop {
  Node test;
  Do(Statement body, this.test) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDo(this);
}

class Continue extends Statement {
  String id;  // Can be null.
  Continue(this.id);

  accept(NodeVisitor visitor) => visitor.visitContinue(this);
}

class Break extends Statement {
  String id;  // Can be null.
  Break(this.id);

  accept(NodeVisitor visitor) => visitor.visitBreak(this);
}

class Return extends Statement {
  Expression expr;  // Can be null.
  Return(this.expr);

  accept(NodeVisitor visitor) => visitor.visitReturn(this);
}

class Throw extends Statement {
  Expression expr;
  Throw(this.expr);

  accept(NodeVisitor visitor) => visitor.visitThrow(this);
}

class Try extends Statement {
  Block body;
  Catch catchPart;
  Block finallyPart;
  Try(this.body, this.catchPart, this.finallyPart);

  accept(NodeVisitor visitor) => visitor.visitTry(this);
}

class Catch extends Node {
  Decl decl;
  Block body;
  Catch(this.decl, this.body);

  accept(NodeVisitor visitor) => visitor.visitCatch(this);
}

class With extends Statement {
  Expression object;
  Statement body;
  With(this.object, this.body);

  accept(NodeVisitor visitor) => visitor.visitWith(this);
}

class Switch extends Statement {
  Expression key;
  List<SwitchClause> cases;
  Switch(this.key, this.cases);

  accept(NodeVisitor visitor) => visitor.visitSwitch(this);
}

abstract class SwitchClause extends Node {
  Block body;
  SwitchClause(this.body);
}

class Case extends SwitchClause {
  Expression expr;
  Case(this.expr, Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitCase(this);
}

class Default extends SwitchClause {
  Default(Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDefault(this);
}

class FunctionDeclaration extends Statement {
  Decl id;
  Fun fun;
  FunctionDeclaration(this.id, this.fun);

  accept(NodeVisitor visitor) => visitor.visitFunctionDeclaration(this);
}

class Labeled extends Statement {
  String id;
  Statement body;
  Labeled(this.id, this.body);

  accept(NodeVisitor visitor) => visitor.visitLabeled(this);
}

abstract class Expression extends Node {
  const Expression();
}

class Sequence extends Expression {
  List<Expression> expressions;
  Sequence(this.expressions);

  accept(NodeVisitor visitor) => visitor.visitSequence(this);
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
}

class VassignOp extends Vassign {
  Ref op;
  VassignOp(Ref lhs, this.op, Expression val) : super(lhs, val);

  accept(NodeVisitor visitor) => visitor.visitVassignOp(this);
}

class Accsign extends Assign {
  Access lhs;
  Accsign(this.lhs, Expression val): super(val);

  accept(NodeVisitor visitor) => visitor.visitAccsign(this);
}

class AccsignOp extends Accsign {
  Ref op;
  AccsignOp(Access lhs, this.op, Expression val) : super(lhs, val);

  accept(NodeVisitor visitor) => visitor.visitAccsignOp(this);
}

class Conditional extends Expression {
  Expression test;
  Expression then;
  Expression otherwise;
  Conditional(this.test, this.then, this.otherwise);

  accept(NodeVisitor visitor) => visitor.visitConditional(this);
}

class New extends Expression {
  Expression cls;
  List<Expression> arguments;
  New(this.cls, this.arguments);

  accept(NodeVisitor visitor) => visitor.visitNew(this);
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;
  Call(this.target, this.arguments);

  accept(NodeVisitor visitor) => visitor.visitCall(this);
}

class Binary extends Call {
  Binary(Ref op, List<Expression> args) : super(op, args);

  accept(NodeVisitor visitor) => visitor.visitBinary(this);
}

class Unary extends Call {
  Unary(Ref op, List<Expression> arg) : super(op, arg);

  accept(NodeVisitor visitor) => visitor.visitUnary(this);
}

class Postfix extends Call {
  Postfix(Ref op, List<Expression> arg) : super(op, arg);

  accept(NodeVisitor visitor) => visitor.visitPostfix(this);
}

class Ref extends Expression {
  final String id;
  const Ref(this.id);

  accept(NodeVisitor visitor) => visitor.visitRef(this);
}

class This extends Ref {
  const This() : super("this");

  accept(NodeVisitor visitor) => visitor.visitThis(this);
}

class Decl extends Ref {
  Decl(String id) : super(id);

  accept(NodeVisitor visitor) => visitor.visitDecl(this);
}

class Param extends Decl {
  Param(String id) : super(id);

  accept(NodeVisitor visitor) => visitor.visitParam(this);
}

class NamedFunction extends Expression {
  Decl id;
  Fun fun;
  NamedFunction(this.id, this.fun);

  accept(NodeVisitor visitor) => visitor.visitNamedFunction(this);
}

class Fun extends Expression {
  List<Param> params;
  Block body;
  Fun(this.params, this.body);

  accept(NodeVisitor visitor) => visitor.visitFun(this);
}

class Access extends Expression {
  Expression receiver;
  Expression selector;
  Access(this.receiver, this.selector);

  accept(NodeVisitor visitor) => visitor.visitAccess(this);
}

abstract class Literal extends Expression {
  const Literal();
}

class BoolLiteral extends Literal {
  final bool value;
  const BoolLiteral(this.value);

  accept(NodeVisitor visitor) => visitor.visitBoolLiteral(this);
}

class UndefinedLiteral extends Literal {
  const UndefinedLiteral();

  accept(NodeVisitor visitor) => visitor.visitUndefinedLiteral(this);
}

class NullLiteral extends Literal {
  const NullLiteral();

  accept(NodeVisitor visitor) => visitor.visitNullLiteral(this);
}

class StringLiteral extends Literal {
  final String value;
  const StringLiteral(this.value);

  accept(NodeVisitor visitor) => visitor.visitStringLiteral(this);
}

class NumberLiteral extends Literal {
  final String value;
  const NumberLiteral(this.value);

  accept(NodeVisitor visitor) => visitor.visitNumberLiteral(this);
}

// Despite being called "Literal" the [ArrayLiteral] does not inherit from
// [Literal].
class ArrayLiteral extends Expression {
  int length;
  List<ArrayElement> elements;
  ArrayLiteral(this.length, this.elements);

  accept(NodeVisitor visitor) => visitor.visitArrayLiteral(this);
}

class ArrayElement extends Node {
  int index;
  Expression value;
  ArrayElement(this.index, this.value);

  accept(NodeVisitor visitor) => visitor.visitArrayElement(this);
}

// Despite being called "Literal" the [ObjectLiteral] does not inherit from
// [Literal].
class ObjectLiteral extends Expression {
  List<PropertyInit> properties;
  ObjectLiteral(this.properties);

  accept(NodeVisitor visitor) => visitor.visitObjectLiteral(this);
}

class PropertyInit extends Node {
  Literal name;
  Expression value;
  PropertyInit(this.name, this.value);

  accept(NodeVisitor visitor) => visitor.visitPropertyInit(this);
}