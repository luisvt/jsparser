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

#library("lexer");

final List<String> KEYWORDS = const <String>[
    "as", "break", "case", "catch", "class", "const", "continue", "default",
    "delete", "do", "else", "extends", "false", "finally", "for", "function",
    "if", "import", "in", "instanceof", "is", "namespace", "new", "null",
    "package", "private", "public", "return", "super", "switch", "this",
    "throw", "true", "try", "typeof", "use", "var", "void", "while", "with"];

final List<String> FUTURE_RESERVED = const <String>[
    "abstract", "debugger", "enum", "export", "goto", "implements", "interface",
    "native", "protected", "synchronized", "throws", "transient", "volatile"];

Set<String> _keywordSet = null;
Set<String> get keywordSet() {
  if (_keywordSet === null) {
    _keywordSet = new Set<String>();
    for (String keyword in KEYWORDS) _keywordSet.add(keyword);
  }
  return _keywordSet;
}

Set<String> _futureReservedSet = null;
Set<String> get futureReservedSet() {
  if (_futureReservedSet === null) {
    _futureReservedSet = new Set<String>();
    for (String reserved in FUTURE_RESERVED) _futureReservedSet.add(reserved);
  }
  return _futureReservedSet;
}

bool CARE_FUTURE_RESERVED = true;

bool isReserved(String symbol) {
  if (keywordSet.contains(symbol)) return true;
  if (CARE_FUTURE_RESERVED && futureReservedSet.contains(symbol)) return true;
  return false;
}

class Token {
  final String type;
  final int position;
  final value;
  const Token(this.type, this.position, [this.value]);

  String toString() => "$type ($position): $value";
}

// TODO(floitsch): is \x10 a line terminator?
final LINE_TERMINATORS = "\x13\n";
final BLANKS = " \t\x10\x12\x13\n";
final BLANKS_NO_LINE_TERMINATORS = " \t\x12";
final DIGITS = "0123456789";
final HEX ="${DIGITS}ABCDEFabcdef";

class Lexer {
  final String input;
  int position = 0;
  Lexer(this.input);

  bool isInStringSet(String c, String set) {
    for (int i = 0; i < set.length; i++) {
      if (set[i] == c) return true;
    }
    return false;
  }

  bool isBlank(String c) => isInStringSet(c, BLANKS);
  bool isDigit(String c) => isInStringSet(c, DIGITS);
  bool isHex(String c) => isInStringSet(c, HEX);
  bool isLineTerminator(String c) => isInStringSet(c, LINE_TERMINATORS);
  bool isBlankNoLineTerminator(String c)
      => isInStringSet(c, BLANKS_NO_LINE_TERMINATORS);
  bool isIdStart(String c) {
    int $a = "a".charCodeAt(0);
    int $z = "z".charCodeAt(0);
    int $A = "A".charCodeAt(0);
    int $Z = "Z".charCodeAt(0);
    if (c == "\$" || c == "_") return true;
    int cValue = c.charCodeAt(0);
    return ($a <= cValue && cValue <= $z ||
            $A <= cValue && cValue <= $Z);
  }
  bool isIdPart(String c) => isIdStart(c) || isDigit(c);


  bool charsLeft() => position < input.length;

  void eatBlanks() {
    while (charsLeft() && isBlankNoLineTerminator(input[position])) {
      position++;
    }
  }

  void eatLineTerminators() {
    while (charsLeft() && isLineTerminator(input[position])) {
      position++;
    }
  }

  bool pointsTo(String str) {
    if (position + str.length < input.length) {
      for (int i = 0; i < str.length; i++) {
        if (input[position + i] != str[i]) return false;
      }
      return true;
    }
    return false;
  }

  void eatUntilLineTerminator() {
    while (charsLeft() && !isLineTerminator(input[position])) position++;
  }

  void eatDigits() {
    while (charsLeft() && isDigit(input[position])) position++;
  }

  void eatHex() {
    while (charsLeft() && isHex(input[position])) position++;
  }

  Token readString(String startChar) {
    assert(charsLeft());
    assert(input[position] == startChar);
    int startPos = position;
    position++;
    bool sawBackslash = false;
    while (charsLeft()) {
      if (sawBackslash) {
        sawBackslash = false;
        position++;
      } else {
        if (input[position] == startChar) {
          position++;
          String value = input.substring(startPos, position);
          return new Token("STRING", startPos, value);
        }
        sawBackslash = (input[position++] == "\\");
      }
    }
    throw "Unterminated string $startPos";
  }

  Token readKeywordOrIdentifier() {
    assert(isIdStart(input[position]));
    int startPos = position;
    while (charsLeft() && isIdPart(input[position])) position++;
    String value = input.substring(startPos, position);
    if (isReserved(value)) {
      return new Token(value.toUpperCase(), startPos, value);
    }
    return new Token("ID", startPos, value);
  }

  /**
   * Returns null if no line terminator was found. Throws if the comment was not
   * terminated. Otherwise returns the position of the first new line in the
   * comment.
   */
  int eatMultiLineComment() {
    int startPos = position;
    bool sawStar = false;
    int lineTerminatorPosition = null;
    while (charsLeft()) {
      String c = input[position++];
      if (c == "/" && sawStar) return lineTerminatorPosition;
      if (lineTerminatorPosition === null && isLineTerminator(c)) {
        lineTerminatorPosition = position - 1;
      }
      sawStar =  (c == "*");
    }
    throw "Unterminated multi-line comment $startPos";
  }

  Token readNumber() {
    Token createNumberToken(int startPos) {
      String value = input.substring(startPos, position);
      return new Token("NUMBER", startPos, value);
    }

    assert(isDigit(input[position]) || input[position] == '.');
    bool startsWithDot = input[position] == '.';
    if (startsWithDot) position++;
    int startPos = position;
    eatDigits();
    String c = input[position];
    if (c == "." && !startsWithDot) {
      // Floating-point constant.
      position++;
      if (charsLeft() && isDigit(input[position])) {
        eatDigits();
        if (charsLeft() &&
            (input[position] == "e" || input[position] == "E")) {
          position++;  // Eat the "e" or "E";
          if (charsLeft() &&
              (input[position] == "+" || input[position] == "-")) {
            position++;  // Eat the exponent sign.
          }
          if (!charsLeft() || !isDigit(input[position])) {
            throw "Unterminated number literal $startPos";
          }
          eatDigits();
        }
      }
    } else if (c == "x" || c == "X") {
      // Hexadecimal
      position++;
      if (!charsLeft() || !isHex(input[position])) {
        throw "Unterminated number literal $startPos";
      }
      eatHex();
    }
    return createNumberToken(startPos);
  }


  Token get eofToken() => new Token("EOF", input.length);
  Token consumeSymbolToken(String symbol) {
    int len = symbol.length;
    int pos = position;
    position += len;
    return new Token(symbol, pos, symbol);
  }

  Token next() {
    eatBlanks();
    // Line comments.
    if (pointsTo("//")) {
      eatUntilLineTerminator();
    }
    if (pointsTo("/*")) {
      // Make sure we don't skip line terminators;
      int lineTerminatorPosition = eatMultiLineComment();
      if (lineTerminatorPosition !== null) {
        return new Token("NEW_LINE", lineTerminatorPosition);
      }
    }
    if (position >= input.length) return eofToken;
    String c = input[position];
    // New lines.
    if (isLineTerminator(c)) {
      Token result = new Token("NEW_LINE", position);
      eatLineTerminators();
      return result;
    }
    // Number constants.
    // TODO(floitsch): handle octal numbers.
    if (isInStringSet(c, DIGITS)) {
      return readNumber();
    }
    switch (c) {
      case "{": return new Token("LBRACE", position++, c);
      case "}": return new Token("RBRACE", position++, c);
      case "(": return new Token("LPAREN", position++, c);
      case ")": return new Token("RPAREN", position++, c);
      case "[": return new Token("LBRACKET", position++, c);
      case "]": return new Token("RBRACKET", position++, c);
      case ";": return new Token("SEMICOLON", position++, c);
      case ",": return new Token("COMMA", position++, c);
      case ":":
      case "?":
      case "~":
        return new Token(c, position++, c);
      case ".":
        position++;
        if (charsLeft() && isDigit(input[position])) {
          position--;
          return readNumber();
        }
        return new Token("DOT", position, c);
      case "|":
        if (pointsTo("||")) return consumeSymbolToken("||");
        if (pointsTo("|=")) return consumeSymbolToken("|=");
        return new Token(c, position++, c);
      case "&":
        if (pointsTo("&&")) return consumeSymbolToken("&&");
        if (pointsTo("&=")) return consumeSymbolToken("&=");
        return new Token(c, position++, c);
      case "<":
        if (pointsTo("<<=")) return consumeSymbolToken("<<=");
        if (pointsTo("<<")) return consumeSymbolToken("<<");
        if (pointsTo("<=")) return consumeSymbolToken("<=");
        return new Token(c, position++, c);
      case ">":
        if (pointsTo(">>>")) return consumeSymbolToken(">>>");
        if (pointsTo(">>=")) return consumeSymbolToken(">>=");
        if (pointsTo(">>")) return consumeSymbolToken(">>");
        if (pointsTo(">=")) return consumeSymbolToken(">=");
        return new Token(c, position++, c);
      case "!":
        if (pointsTo("!==")) return consumeSymbolToken("!==");
        if (pointsTo("!=")) return consumeSymbolToken("!=");
        return new Token(c, position++, c);
      case "=":
        if (pointsTo("===")) return consumeSymbolToken("===");
        if (pointsTo("==")) return consumeSymbolToken("==");
        return new Token(c, position++, c);
      case "+":
      case "-":
      case "*":
      case "/":
      case "%":
      case "^":
        position++;
        if (charsLeft() && input[position] == "=") {
          String symbol = "$c=";
          return new Token(symbol, (position++) - 1, symbol);
        }
        // ++ and --.
        if ((c == "+" || c == "-") && input[position] == c) {
          String symbol = "$c$c";
          return new Token(symbol, (position++) - 1, symbol);
        }
        return new Token(c, position - 1, c);
      case "'":
      case '"':
        return readString(c);
      default:
        if (isIdStart(c)) {
          return readKeywordOrIdentifier();
        }
        throw "Unexpected character $c $position";
    }
  }
}
