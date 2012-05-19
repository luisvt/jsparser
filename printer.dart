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

#library("printer");
#import("nodes.dart");

class Printer implements NodeVisitor {
  StringBuffer outBuffer;
  int indentLevel = 0;

  void out(String str) { outBuffer.add(str); }
  void outLn(String str) { outBuffer.add(str); outBuffer.add("\n"); }
  void outIndent(String str) { indent(); out(str); }
  void outIndentLn(String str) { indent(); outLn(str); }
  void indent() {
    for (int i = 0; i < indentLevel; i++) out("  ");
  }

  Printer() : outBuffer = new StringBuffer();
  visit(Node node) {
    node.accept(this);
  }

  visitInterleaved(List<Node> nodes, String separator) {
    for (int i = 0; i < nodes.length; i++) {
      if (i != 0) out(separator);
      visit(nodes[i]);
    }
  }

  visitAll(List<Node> nodes) {
    nodes.forEach(visit);
  }

  visitProgram(Program program) {
    outLn("/* Program */");
    visitAll(program.body);
  }

  visitBlock(Block block) {
    outIndentLn("{");
    indentLevel++;
    visitAll(block.elements);
    indentLevel--;
    outIndentLn("}");
  }

  visitVariableDeclarationList(VariableDeclarationList list) {
    outIndent("var ");
    visitInterleaved(list.declarations, ", ");
    outLn(";");
  }

  visitExpressionStatement(ExpressionStatement expressionStatement) {
    indent();
    visit(expressionStatement.expr);
    outLn(";");
  }

  visitInit(Init init) {
    visit(init.decl);
    if (init.value !== init.value) {
      out(" = ");
      visit(init.value);
    }
  }

  visitNOP(NOP nop) {
    outIndentLn(";");
  }

  visitIf(If node) {
    outIndent("if (");
    visit(node.test);
    out(")");
    // Visit dangling else problem.
    if (node.hasElse && node.then is If) {
      out(" {\n");
      visit(node.then);
      outIndent("}");
    } else {
      out("\n");
      visit(node.then);
    }
    if (node.hasElse) {
      outIndent("else\n");
      visit(node.otherwise);
      outLn("");
    } else {
      outLn("");
    }
  }

  visitFor(For loop) {
    outIndentLn("for (");
    indentLevel++;
    visit(loop.init);
    indentLevel--;
    visit(loop.test);
    out("; ");
    if (loop.incr !== null) {
      visit(loop.incr);
    }
    out(")\n");
    visit(loop.body);
  }

  visitForIn(ForIn loop) {
  }

  visitWhile(While loop) {
  }

  visitDo(Do loop) {
  }

  visitContinue(Continue cont) {
    outIndentLn("continue;");
  }

  visitBreak(Break node) {
    outIndentLn("break;");
  }

  visitReturn(Return node) {
    outIndent("return ");
    visit(node.expr);
    outLn(";");
  }

  visitThrow(Throw node) {
    outIndent("throw ");
    visit(node.expr);
    outLn(";");
  }

  visitTry(Try node) {
    outIndentLn("try");
    visit(node.body);
    if (node.catchPart !== null) {
      visit(node.catchPart);
    }
    if (node.finallyPart !== null) {
      outIndentLn("finally");
      visit(node.finallyPart);
    }
  }

  visitCatch(Catch node) {
    outIndent("catch (");
    visit(node.decl);
    outLn(")");
    visit(node.body);
  }

  visitWith(With node) {
    outIndent("with(");
    visit(node.object);
    outLn(")");
  }

  visitSwitch(Switch node) {
    outIndent("switch(");
    visit(node.key);
    outLn(") {");
    indentLevel++;
    visitAll(node.cases);
    indentLevel--;
    outIndentLn("}");
  }

  visitCase(Case node) {
    outIndent("case ");
    visit(node.expr);
    outLn(":");
    if (!node.body.elements.isEmpty()) {
      visit(node.body);
    }
  }

  visitDefault(Default node) {
    outIndentLn("default:");
    if (!node.body.elements.isEmpty()) {
      visit(node.body);
    }
  }

  visitFunctionDeclaration(FunctionDeclaration declaration) {
    out("function ");
    visit(declaration.id);
    out("(");
    visitInterleaved(declaration.fun.params, ", ");
    outLn(")");
    visit(declaration.fun.body);
  }

  visitSequence(Sequence sequence) {
    out("(");
    visitInterleaved(sequence.expressions, ", ");
    out(")");
  }

  visitVassign(Vassign vassign) {
    out("(");
    visit(vassign.lhs);
    out("=");
    visit(vassign.val);
    out(")");
  }

  visitAccsign(Accsign accsign) {
    out("(");
    visit(accsign.lhs);
    out("=");
    visit(accsign.val);
    out(")");
  }

  visitVassignOp(VassignOp vassignOp) {
    out("(");
    visit(vassignOp.lhs);
    visit(vassignOp.op);
    visit(vassignOp.val);
    out(")");
  }

  visitAccsignOp(AccsignOp accsignOp) {
    out("(");
    visit(accsignOp.lhs);
    visit(accsignOp.op);
    visit(accsignOp.val);
    out(")");
  }

  visitConditional(Conditional cond) {
    out("(");
    visit(cond.test);
    out(" ? ");
    visit(cond.then);
    out(" : ");
    visit(cond.otherwise);
    out(")");
  }

  visitNew(New node) {
    out("(new ");
    visit(node.cls);
    out("(");
    visitInterleaved(node.arguments, ", ");
    out("))");
  }

  visitCall(Call call) {
    out("(");
    visit(call.target);
    out("(");
    visitInterleaved(call.arguments, ", ");
    out("))");
  }

  visitBinary(Binary binary) {
    out("(");
    visit(binary.arguments[0]);
    visit(binary.target);
    visit(binary.arguments[1]);
    out(")");
  }

  visitUnary(Unary unary) {
    out("(");
    visit(unary.target);
    visit(unary.arguments[0]);
    out(")");
  }

  visitPostfix(Postfix postfix) {
    out("(");
    visit(postfix.arguments[0]);
    visit(postfix.target);
    out(")");
  }

  visitRef(Ref ref) {
    out(ref.id);
  }

  visitThis(This node) {
    out("this");
  }

  visitDecl(Decl decl) {
    out(decl.id);
  }

  visitParam(Param param) {
    out(param.id);
  }

  visitAccess(Access access) {
    out("(");
    visit(access.receiver);
    out("[");
    visit(access.selector);
    out("]");
    out(")");
  }

  visitNamedFunction(NamedFunction namedFunction) {
    out("(function ");
    visit(namedFunction.id);
    out("(");
    visitInterleaved(namedFunction.fun.params, ", ");
    outLn(")");
    visit(namedFunction.fun.body);
    out(")");
  }

  visitFun(Fun fun) {
    out("(function (");
    visitInterleaved(fun.params, ", ");
    outLn(")");
    visit(fun.body);
    out(")");
  }

  visitBoolLiteral(BoolLiteral node) {
    out(node.value ? "true" : "false");
  }

  visitStringLiteral(StringLiteral node) {
    out(node.value);
  }

  visitNumberLiteral(NumberLiteral node) {
    out(node.value);
  }

  visitNullLiteral(NullLiteral node) {
    out("null");
  }

  visitUndefinedLiteral(UndefinedLiteral node) {
    out("(void 0)");
  }

  visitArrayLiteral(ArrayLiteral node) {
    out("[");
    List<ArrayElement> elements = node.elements;
    int elementIndex = 0;
    for (int i = 0; i < node.length; i++) {
      if (elementIndex < elements.length &&
          elements[elementIndex].index == i) {
        visit(elements[elementIndex].value);
        elementIndex++;
        if (i != node.length - 1) out(", ");
      } else {
       out(",");
      }
    }
    out("]");
  }

  visitArrayElement(ArrayElement node) {
    throw "Unreachable";
  }

  visitObjectLiteral(ObjectLiteral node) {
    out("({");
    visitInterleaved(node.properties, ", ");
    out("})");
  }

  visitPropertyInit(PropertyInit node) {
    visit(node.name);
    out(": ");
    visit(node.value);
  }
}
