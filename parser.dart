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

#library("parser");
#import("lexer.dart");
#import("nodes.dart");

class Parser {
  final Lexer lexer;
  List<Token> peekedTokens;
  // Includes new-lines.
  String previousTokenType = null;

  Parser(this.lexer) : this.peekedTokens = <Token>[];

  void error(String msg, var obj, Token token) {
    throw "$msg: $obj. $token";
  }

  void unexpectedToken(Token token) {
    throw "Unexpected token: $token";
  }

  Token peekToken() {
    if (peekedTokens.isEmpty()) {
      Token nextToken;
      while (true) {
        nextToken = lexer.next();
        if (nextToken.type == "NEW_LINE") {
          previousTokenType = nextToken.type;
        } else {
          break;
        }
      }
      peekedTokens.add(nextToken);
    }
    return peekedTokens.last();
  }

  void pushBackToken(Token token) {
    peekedTokens.add(token);
  }

  String peekTokenType() => peekToken().type;

  bool isAtNewLineToken() => previousTokenType == 'NEW_LINE';

  // TODO(floitsch): this returns a value instead of the token. Inconsistent
  // with [consumeAny].
  Dynamic consume(String type) {
    Token token = consumeAny();
    if (token.type == type) return token.value;
    print("Expected: $type");
    unexpectedToken(token);
  }

  void consumeStatementSemicolon() {
    String nextTokenType = peekTokenType();
    if (nextTokenType == "SEMICOLON") {
      consumeAny();
    } else if (nextTokenType == "RBRACE"
        || isAtNewLineToken()
        || nextTokenType == "EOF") {
      // Do nothing.
    } else {
      unexpectedToken(peekToken());
    }
  }

  Token consumeAny() {
    Token result = peekToken();
    previousTokenType = result.type;
    peekedTokens.length--;
    return result;
  }

  bool atEof() => peekTokenType() == "EOF";

  Program parseProgram() => new Program(parseStatements());

  List<Statement> parseStatements() {
    List<Statement> result = <Statement>[];
    while (!atEof()) {
      Statement stmt = parseStatement();
      result.add(stmt);
    }
    return result;
  }

  Statement parseStatement() {
    switch (peekTokenType()) {
      case "LBRACE": return parseBlock();
      case "VAR": return parseVariableDeclarationList(inForInit: false);
      case "SEMICOLON": return parseEmptyStatement();
      case "IF": return parseIf();
      case "FOR": return parseFor();
      case "WHILE": return parseWhile();
      case "DO": return parseDoWhile();
      case "CONTINUE": return parseContinue();
      case "BREAK": return parseBreak();
      case "RETURN": return parseReturn();
      case "WITH": return parseWith();
      case "SWITCH": return parseSwitch();
      case "THROW": return parseThrow();
      case "TRY": return parseTry();
      case "FUNCTION":
        // The Ecmascript specification actually does not allow a function
        // declaration to be at any place where a statement can be, but every
        // engine implements it this way.
        return parseFunctionDeclaration();
      case "ID": return parseLabeledOrExpression();
      default:
        // Errors will be handled in the expression parser.
        return parseExpressionStatement();
    }
  }

  Block parseBlock() {
    consume("LBRACE");
    List<Statement> statements = <Statement>[];
    while (peekTokenType() != "RBRACE") {
      // Errors will be handled in the statement parser.
      statements.add(parseStatement());
    }
    consumeAny();
    return new Block(statements);
  }

  VariableDeclarationList parseVariableDeclarationList([bool inForInit]) {
    assert(inForInit !== null);
    consume("VAR");
    List<Init> declarations = <Init>[parseVar(inForInit)];
    while (true) {
      switch (peekTokenType()) {
        case "SEMICOLON":
          if (!inForInit) consumeAny();
          return new VariableDeclarationList(declarations);
        case "COMMA":
          consumeAny();
          declarations.add(parseVar(inForInit));
          break;
        case "IN":
          if (!inForInit) error("bad token: ", "in", peekToken());
          return new VariableDeclarationList(declarations);
        default:
          if (!inForInit && (isAtNewLineToken() || peekTokenType() == "EOF")) {
            return new VariableDeclarationList(declarations);
          }
          unexpectedToken(consumeAny());
      }
    }
  }

  Init parseVar(bool inForInit) {
    String id = consume("ID");
    if (peekTokenType() == "=") {
      consumeAny();
      return new Init(new Decl(id), parseAssignExpression(inForInit));
    }
    return new Init(new Decl(id), null);
  }

  NOP parseEmptyStatement() {
    consume("SEMICOLON");
    return new NOP();
  }

  If parseIf() {
    consume("IF");
    consume("LPAREN");
    Expression test = parseExpression(false);
    consume("RPAREN");
    Statement then = parseStatement();
    Statement otherwise;
    if (peekTokenType() == "ELSE") {
      consumeAny();
      otherwise = parseStatement();
    } else {
      otherwise = new NOP();
    }
    return new If(test, then, otherwise);
  }

  /** Returns either a [For] or a [ForIn] loop. */
  Loop parseFor() {
    consume("FOR");
    consume("LPAREN");

    Statement firstPart;
    switch (peekTokenType()) {
      case "VAR":
        firstPart = parseVariableDeclarationList(inForInit: true);
        break;
      case "SEMICOLON":
        firstPart = new NOP();
        break;
      default:
        firstPart = new ExpressionStatement(parseExpression(true));
    }

    switch (peekTokenType()) {
      case "SEMICOLON": return parseForInitTestIncr(firstPart);
      case "IN": return parseForIn(firstPart);
      default: throw "internal error";
    }
  }

  // for (init; test; incr) body;
  For parseForInitTestIncr(Statement init) {
    consume("SEMICOLON");
    Expression test;
    if (peekTokenType() == "SEMICOLON") {
      test = new BoolLiteral("true");
    } else {
      test = parseExpression(false);
    }
    consume("SEMICOLON");

    Expression incr;
    if (peekTokenType() != "RPAREN") {
      incr = parseExpression(false);
    }
    consume("RPAREN");

    Statement body = parseStatement();
    return new For(init, test, incr, body);
  }

  ForIn parseForIn(Statement firstPart) {
    Token errorToken = peekToken();
    consume("IN");
    Expression obj = parseExpression(false);
    consume("RPAREN");
    Statement body = parseStatement();
    if (firstPart is VariableDeclarationList) {
      VariableDeclarationList varDecl = firstPart;
      if (varDecl.declarations.length != 1) {
        error("Only one variable allowed in 'for-in' statement",
              varDecl.declarations[1].decl.id,
              errorToken);
      }
      return new ForIn(firstPart, obj, body);
    } else if (firstPart is Ref || firstPart is Access) {
      return new ForIn(firstPart, obj, body);
    } else
      error("Bad left-hand side in 'for-in' loop construct",
            firstPart,
            errorToken);
  }

  While parseWhile() {
    consume("WHILE");
    consume("LPAREN");
    Expression test = parseExpression(false);
    consume("RPAREN");
    Statement body = parseStatement();
    return new While(test, body);
  }

  Do parseDoWhile() {
    consume("DO");
    Statement body = parseStatement();
    consume("WHILE");
    consume("LPAREN");
    Expression test = parseExpression(false);
    consume("RPAREN");
    consumeStatementSemicolon();
    return new Do(body, test);
  }

  Continue parseContinue() {
    consume("CONTINUE");
    if (!isAtNewLineToken() && peekTokenType() == "ID") {
      String id = consume("ID");
      consumeStatementSemicolon();
      return new Continue(id);
    } else {
      consumeStatementSemicolon();
      return new Continue(null);
    }
  }

  Break parseBreak() {
    consume("BREAK");
    if (!isAtNewLineToken() && peekTokenType() == "ID") {
      String id = consume("ID");
      consumeStatementSemicolon();
      return new Break(id);
    } else {
      consumeStatementSemicolon();
      return new Break(null);
    }
  }

  Return parseReturn() {
    consume("RETURN");
    Expression value;
    if (isAtNewLineToken()) {
      value = new UndefinedLiteral();
    } else {
      switch (peekTokenType()) {
        case "EOF":
        case "ERROR":
        case "SEMICOLON":
          value = new UndefinedLiteral();
          break;
        default:
          value = parseExpression(false);
      }
      consumeStatementSemicolon();
      return new Return(value);
    }
  }

  With parseWith() {
    consume("WITH");
    consume("LPAREN");
    Expression expr = parseExpression(false);
    consume("RPAREN");
    Statement body = parseStatement();
    return new With(expr, body);
  }

  Switch parseSwitch() {
    consume("SWITCH");
    consume("LPAREN");
    Expression key = parseExpression(false);
    consume("RPAREN");
    List<SwitchClause> clauses = parseCaseBlock();
    return new Switch(key, clauses);
  }

  List<SwitchClause> parseCaseBlock() {
    consume("LBRACE");
    List<SwitchClause> clauses = <SwitchClause>[];
    bool defaultCaseIsDone = false;
    while(peekTokenType() != "RBRACE") {
      switch (peekTokenType()) {
        case "CASE":
          clauses.add(parseCaseClause());
          break;
        case "DEFAULT":
          if (defaultCaseIsDone) {
            error("Only one default-clause allowed", peekToken(), peekToken());
          }
          clauses.add(parseDefaultClause());
      }
    }
    consume("RBRACE");
    return clauses;
  }

  Case parseCaseClause() {
    consume("CASE");
    Expression expr = parseExpression(false);
    consume(":");
    Block body = parseSwitchClauseStatements();
    return new Case(expr, body);
  }

  Default parseDefaultClause() {
    consume("DEFAULT");
    consume(":");
    return new Default(parseSwitchClauseStatements());
  }

  Block parseSwitchClauseStatements() {
    List<Statement> statements = <Statement>[];
    while (true) {
      switch (peekTokenType()) {
        case "RBRACE":
        case "EOF":
        case "ERROR":
        case "DEFAULT":
        case "CASE":
          return new Block(statements);
        default:
          statements.add(parseStatement());
      }
    }
  }

  Throw parseThrow() {
    consume("THROW");
    if (isAtNewLineToken()) {
      error("throw must have a value", null, peekToken());
    }
    Expression expr = parseExpression(false);
    consumeStatementSemicolon();
    return new Throw(expr);
  }

  Try parseTry() {
    Token errorToken = peekToken();
    consume("TRY");
    Block body = parseBlock();
    Catch catchPart = null;
    Block finallyPart = null;
    if (peekTokenType() == "CATCH") {
      catchPart = parseCatch();
    }
    if (peekTokenType() == "FINALLY") {
      finallyPart = parseFinally();
    }
    if (catchPart === null && finallyPart === null) {
      error("Try without catch and finally", null, errorToken);
    }
    return new Try(body, catchPart, finallyPart);
  }

  Catch parseCatch() {
    consume("CATCH");
    consume("LPAREN");
    String id = consume("ID");
    consume("RPAREN");
    Block body = parseBlock();
    return new Catch(new Param(id), body);
  }

  Block parseFinally() {
    consume("FINALLY");
    return parseBlock();
  }

  Statement parseLabeledOrExpression() {
    Token idToken = consumeAny();
    String nextTokenType = peekTokenType();
    assert(idToken.type == "ID");
    pushBackToken(idToken);
    if (nextTokenType == ":") {
      return parseLabeled();
    } else {
      return parseExpressionStatement();
    }
  }

  Statement parseExpressionStatement() {
    Expression expr = parseExpression(false);
    consumeStatementSemicolon();
    return new ExpressionStatement(expr);
  }

  Labeled parseLabeled() {
    String id = consume("ID");
    consume(":");
    return new Labeled(id, parseStatement());
  }

  FunctionDeclaration parseFunctionDeclaration() => parseFunction(true);
  /** Returns either a Function or a NamedFunction */
  Expression parseFunctionExpression() => parseFunction(false);

  Node parseFunction(isDeclaration) {
    consume("FUNCTION");
    String id = null;
    if (isDeclaration || peekTokenType() == "ID") id = consume("ID");
    List<Param> params = parseParameters();
    // According to the spec we cannot just parse a body, but must
    Block body = parseBlock();
    Fun fun = new Fun(params, body);
    if (isDeclaration) return new FunctionDeclaration(new Decl(id), fun);
    if (id !== null) return new NamedFunction(new Decl(id), fun);
    return fun;
  }

  List<Param> parseParameters() {
    List<Param> result = <Param>[];
    consume("LPAREN");
    if (peekTokenType() == "RPAREN") {
      consumeAny();
      return result;
    }
    while(true) {
      result.add(new Param(consume("ID")));
      if (peekTokenType() != "COMMA") break;
      consumeAny();
    }
    consume("RPAREN");
    return result;
  }

  Expression parseExpression(bool inForInit) => parseSequence(inForInit);

  Expression parseSequence(bool inForInit) {
    Expression expr = parseAssignExpression(inForInit);
    if (peekTokenType() == "COMMA") {
      List<Expression> expressions = <Expression>[expr];
      while (peekTokenType() == "COMMA") {
        consumeAny();
        expressions.add(parseAssignExpression(inForInit));
      }
      return new Sequence(expressions);
    } else {
      return expr;
    }
  }

  bool isAssignOperator(String tokenType) {
    switch (tokenType) {
      case "=": case "*=": case "/=": case "%=": case "+=": case "-=":
      case "<<=": case ">>=": case ">>>=": case "&=": case "^=": case "|=":
        return true;
      default:
        return false;
    }
  }

  Expression parseAssignExpression(bool inForInit) {
    removeEquals(String op) {
      assert(op[op.length - 1] == "=");
      return op.substring(0, op.length - 1);
    }

    Token errorToken = peekToken();
    Expression expr = parseConditionalExpression(inForInit);
    if (!isAssignOperator(peekTokenType())) return expr;
    String op = consumeAny().value;
    Expression rhs = parseAssignExpression(inForInit);
    if ((op == "=") && expr is Access) return new Accsign(expr, rhs);
    if ((op == "=") && expr is Ref) return new Vassign(expr, rhs);
    if (op == "=") error("bad assignment", null, errorToken);
    if (expr is Access) {
      op = removeEquals(op);
      return new AccsignOp(expr, new Ref(op), rhs);
    }
    if (expr is Ref) {
      op = removeEquals(op);
      return new VassignOp(expr, new Ref(op), rhs);
    }
    error("bad assignment", null, errorToken);
  }

  Expression parseConditionalExpression(bool inForInit) {
    Expression expr = parseBinaryExpression(inForInit);
    if (peekTokenType() != "?") return expr;
    consumeAny();
    Expression then = parseAssignExpression(false);
    consume(":");
    Expression otherwise = parseAssignExpression(inForInit);
    return new Conditional(expr, then, otherwise);
  }

  int operatorLevel(String tokenType) {
    switch (tokenType) {
      case "||": return 1;
      case "&&": return 2;
      case "|": return 3;
      case "^": return 4;
      case "&": return 5;
      case "==":
      case "!=":
      case "===":
      case "!==": return 6;
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "INSTANCEOF":
      case "IN": return 7;
      case "<<":
      case ">>":
      case ">>>": return 8;
      case "+":
      case "-": return 9;
      case "*":
      case "/":
      case "%": return 10;
      default: return null;
    }
  }

  // Left-associative binary expression.
  Expression parseBinaryExpression(bool inForInit) {
    Expression parseBinaryExpressionOfLevel(int level) {
      if (level > 10) return parseUnary();
      Expression expr = parseBinaryExpressionOfLevel(level + 1);
      while (true) {
        String type = peekTokenType();
        if (inForInit && type == "IN") return expr;
        int newLevel = operatorLevel(type);
        if (newLevel === null) return expr;
        if (newLevel != level) return expr;
        String op = consumeAny().value;
        Expression other = parseBinaryExpressionOfLevel(level + 1);
        expr = new Binary(new Ref(op), <Expression>[expr, other]);
      }
    }

    return parseBinaryExpressionOfLevel(1);
  }

  Expression parseUnary() {
    switch (peekTokenType()) {
      case "DELETE":
      case "VOID":
      case "TYPEOF":
      case "~":
      case "!":
      case "++":
      case "--":
        Ref op = new Ref(consumeAny().value);
        Expression expr = parseUnary();
        return new Unary(op, <Expression>[expr]);
      case "+":
      case "-":
        Ref op = new Ref("unary-" + consumeAny().value);
        Expression expr = parseUnary();
        return new Unary(op, <Expression>[expr]);
      default:
        return parsePostfix();
    }
  }

  Expression parsePostfix() {
    Expression lhs = parseLeftHandSide();
    if (!isAtNewLineToken() &&
        (peekTokenType() == "++" || peekTokenType() == "--")) {
      Ref op = new Ref(consumeAny().value);
      return new Postfix(op, <Expression>[lhs]);
    }
    return lhs;
  }

  // We start by getting all news (parseNewExpression).
  // The remaining access and calls are then caught by the parseAccessOrCall
  // invocation allowing call-parenthesis.
  //
  // The parseAccessOrCall in parseNewExpression does not allow any parenthesis
  // to be consumed as they would be part of the NewExpression.
  Expression parseLeftHandSide() {
    return parseAccessOrCall(parseNewExpression(), true);
  }

  Expression parseNewExpression() {
    if (peekTokenType() != "NEW") {
      return parseAccessOrCall(parsePrimary(), false);
    }
    consumeAny();
    Expression cls = parseNewExpression();
    List<Expression> args = peekTokenType() == "LPAREN"
                            ? parseArguments()
                            : <Expression>[];
    return new New(cls, args);
  }

  Expression parseAccessOrCall(Expression expr, bool callsAreAllowed) {
    String parseFieldName() {
      if (peekTokenType() == "ID") return consume("ID");
      // TODO(floitsch): allow reserved identifiers as field names.
      unexpectedToken(consumeAny());
    }

    while (true) {
      switch (peekTokenType()) {
        case "LBRACKET":
          consumeAny();
          Expression field = parseExpression(false);
          consume("RBRACKET");
          expr = new Access(expr, field);
          break;
        case "DOT":
          consumeAny();
          String field = parseFieldName();
          // Transform o.x into o["x"].
          expr = new Access(expr, new StringLiteral('"$field"'));
          break;
        case "LPAREN":
          if (callsAreAllowed) {
            expr = new Call(expr, parseArguments());
          } else {
            return expr;
          }
          break;
        default:
          return expr;
      }
    }
  }

  List<Expression> parseArguments() {
    consume("LPAREN");
    List<Expression> result = <Expression>[];
    if (peekTokenType() == "RPAREN") {
      consumeAny();
      return result;
    }
    result.add(parseAssignExpression(false));
    while (peekTokenType() != "RPAREN") {
      consume("COMMA");
      result.add(parseAssignExpression(false));
    }
    consumeAny();
    return result;
  }

  Expression parsePrimary() {
    switch (peekTokenType()) {
      case "FUNCTION":
        return parseFunctionExpression();
      case "THIS":
        consumeAny();
        return new This();
      case "ID":
        return new Ref(consume("ID"));
      case "LPAREN":
        consumeAny();
        Expression expr = parseExpression(false);
        consume("RPAREN");
        return expr;
      case "LBRACKET":
        return parseArrayLiteral();
      case "LBRACE":
        return parseObjectLiteral();
      case "NULL":
        consumeAny();
        return new NullLiteral();
      case "TRUE":
      case "FALSE":
        return new BoolLiteral(consumeAny().value == "true");
      case "NUMBER":
        return new NumberLiteral(consumeAny().value);  // Stays a string.
      case "STRING":
        return new StringLiteral(consumeAny().value);  // Still with quotes.
      case "/":
      case "/=":
        // TODO(floitsch): parse regexps.
        throw "Unimplemented regexp literal";
      default:
        unexpectedToken(peekToken());
    }
  }

  ArrayLiteral parseArrayLiteral() {
    // Basically: every array-element finishes with ",".
    //   However, the very last one can be avoided if the array-element is not
    //   an ellision.
    // In other words: [a,] and [a] are equivalent, but [,] and [] are not.
    // Whenever we find a (non-empty) array-element, we automatically consume
    // the "," (if it exists).
    consume("LBRACKET");
    List<ArrayElement> elements = <ArrayElement>[];
    int length = 0;
    while (true) {
      switch (peekTokenType()) {
        case "RBRACKET":
          consumeAny();
          return new ArrayLiteral(length, elements);
        case "COMMA":
          consumeAny();
          length++;
          break;
        default:
          elements.add(new ArrayElement(length, parseAssignExpression(false)));
          length++;
          if (peekTokenType() != "RBRACKET") {
            consume("COMMA");
          }
      }
    }
  }

  ObjectLiteral parseObjectLiteral() {
    Literal parsePropertyName() {
      switch (peekTokenType()) {
        case "ID":
          // For simplicity transform the identifier into a string.
          // Example: foo -> "foo".
          String id = consume("ID");
          return new StringLiteral('"$id"');
        case "STRING":
          return new StringLiteral(consume("STRING"));
        case "NUMBER":
          return new NumberLiteral(consume("NUMBER"));
        default:
          // TODO(floitsch): allow reserved identifiers as field names.
          unexpectedToken(consumeAny());
      }
    }

    PropertyInit parsePropertyInit() {
      Literal name = parsePropertyName();
      consume(":");
      Expression value = parseAssignExpression(false);
      return new PropertyInit(name, value);
    }

    consume("LBRACE");
    List<PropertyInit> properties = <PropertyInit>[];
    while (peekTokenType() != "RBRACE") {
      if (!properties.isEmpty()) consume("COMMA");
      properties.add(parsePropertyInit());
    }
    consumeAny();  // The "RBRACE";
    return new ObjectLiteral(properties);
  }
}
