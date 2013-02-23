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

library printer;
import "nodes.dart";

class Printer implements NodeVisitor {
  StringBuffer outBuffer;
  int indentLevel = 0;

  void out(String str) { outBuffer.write(str); }
  void outLn(String str) { outBuffer.write(str); outBuffer.write("\n"); }
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
    visitAll(block.statements);
    indentLevel--;
    outIndentLn("}");
  }

  visitExpressionStatement(ExpressionStatement expressionStatement) {
    indent();
    visit(expressionStatement.expression);
    outLn(";");
  }

  visitEmptyStatement(EmptyStatement nop) {
    outIndentLn(";");
  }

  visitIf(If node) {
    outIndent("if (");
    visit(node.condition);
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
    outIndent("for (");
    if (loop.init != null) visit(loop.init);
    out("; ");
    if (loop.condition != null) visit(loop.condition);
    out("; ");
    if (loop.update != null) visit(loop.update);
    outLn(")");
    if (loop.body is Block) {
      visit(loop.body);
    } else {
      indentLevel++;
      visit(loop.body);
      indentLevel--;
    }
  }

  visitForIn(ForIn loop) {
    outIndent("for (");
    visit(loop.leftHandSide);
    out(" in ");
    visit(loop.object);
    outLn(")");
    if (loop.body is Block) {
      visit(loop.body);
    } else {
      indentLevel++;
      visit(loop.body);
      indentLevel--;
    }
  }

  visitWhile(While loop) {
    outIndent("while (");
    visit(loop.condition);
    outLn(")");
    if (loop.body is Block) {
      visit(loop.body);
    } else {
      indentLevel++;
      visit(loop.body);
      indentLevel--;
    }
  }

  visitDo(Do loop) {
    outIndentLn("do");
    if (loop.body is Block) {
      visit(loop.body);
    } else {
      indentLevel++;
      visit(loop.body);
      indentLevel--;
    }
    outIndent("while (");
    visit(loop.condition);
    outLn(");");
  }

  visitContinue(Continue cont) {
    outIndentLn("continue;");
  }

  visitBreak(Break node) {
    outIndentLn("break;");
  }

  visitReturn(Return node) {
    outIndent("return ");
    visit(node.value);
    outLn(";");
  }

  visitThrow(Throw node) {
    outIndent("throw ");
    visit(node.expression);
    outLn(";");
  }

  visitTry(Try node) {
    outIndentLn("try");
    visit(node.body);
    if (node.catchPart != null) {
      visit(node.catchPart);
    }
    if (node.finallyPart != null) {
      outIndentLn("finally");
      visit(node.finallyPart);
    }
  }

  visitCatch(Catch node) {
    outIndent("catch (");
    visit(node.declaration);
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
    visit(node.expression);
    outLn(":");
    if (!node.body.statements.isEmpty) {
      visit(node.body);
    }
  }

  visitDefault(Default node) {
    outIndentLn("default:");
    if (!node.body.statements.isEmpty) {
      visit(node.body);
    }
  }

  visitLabeledStatement(LabeledStatement node) {
    outIndentLn("${node.label}:");
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration declaration) {
    outIndent("function ");
    visit(declaration.name);
    out("(");
    visitInterleaved(declaration.function.params, ", ");
    outLn(")");
    visit(declaration.function.body);
  }

  visitVariableDeclarationList(VariableDeclarationList list) {
    out("var ");
    visitInterleaved(list.declarations, ", ");
  }

  visitSequence(Sequence sequence) {
    out("(");
    visitInterleaved(sequence.expressions, ", ");
    out(")");
  }

  visitAssignment(Assignment node) {
    out("(");
    visit(node.leftHandSide);
    if (node.isCompound) {
      out(node.op);
      out("=");
    }
    visit(node.value);
    out(")");
  }

  visitVariableInitialization(VariableInitialization init) {
    visit(init.declaration);
    if (init.value != null) {
      out(" = ");
      visit(init.value);
    }
  }

  visitConditional(Conditional cond) {
    out("(");
    visit(cond.condition);
    out(" ? ");
    visit(cond.then);
    out(" : ");
    visit(cond.otherwise);
    out(")");
  }

  visitNew(New node) {
    out("(new ");
    visit(node.target);
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

  visitPrefix(Prefix unary) {
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

  visitVariableUse(VariableUse ref) {
    out(ref.name);
  }

  visitThis(This node) {
    out("this");
  }

  visitVariableDeclaration(VariableDeclaration decl) {
    out(decl.name);
  }

  visitParameter(Parameter param) {
    out(param.name);
  }

  visitPropertyAccess(PropertyAccess access) {
    visit(access.receiver);
    out("[");
    visit(access.selector);
    out("]");
  }

  visitNamedFunction(NamedFunction namedFunction) {
    out("(function ");
    visit(namedFunction.name);
    out("(");
    visitInterleaved(namedFunction.function.params, ", ");
    outLn(")");
    visit(namedFunction.function.body);
    out(")");
  }

  visitFun(Fun fun) {
    out("(function (");
    visitInterleaved(fun.params, ", ");
    outLn(")");
    visit(fun.body);
    outIndent(")");
  }

  visitLiteralBool(LiteralBool node) {
    out(node.value ? "true" : "false");
  }

  visitLiteralString(LiteralString node) {
    out(node.value);
  }

  visitLiteralNumber(LiteralNumber node) {
    out(node.value);
  }

  visitLiteralNull(LiteralNull node) {
    out("null");
  }

  visitLiteralUndefined(LiteralUndefined node) {
    out("(void 0)");
  }

  visitArrayInitializer(ArrayInitializer node) {
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

  visitObjectInitializer(ObjectInitializer node) {
    out("({");
    visitInterleaved(node.properties, ", ");
    out("})");
  }

  visitProperty(Property node) {
    visit(node.name);
    out(": ");
    visit(node.value);
  }

  visitRegExpLiteral(RegExpLiteral node) {
    out(node.pattern);
  }
}
