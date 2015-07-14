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

library jsdart;

import "dart:io";
import "lexer.dart";
import "nodes.dart";
import "parser.dart";
import "printer.dart";
import "resolver.dart";
import "var.dart";

void main(List<String> args) {
  bool printResolution = (args.length == 2 && args[0] == "--print-resolution");
  if (args.length != 1 && !printResolution) {
    printUsage();
    return;
  }
  File file = new File(args[printResolution ? 1 : 0]);
  file.readAsString().then((String content) {
    Parser parser = new Parser(new Lexer(content));
    Program program = parser.parseProgram();
    Map<Node, Var> resolution = resolve(program);
    Printer printer = printResolution ? new ResolverPrinter(resolution) : new Printer();
    printer.visit(program);
    print(printer.outBuffer);
  });
}

void printUsage() {
  print("Usage: dart jsparser.dart [--print-resolution] <file.js>");
}
