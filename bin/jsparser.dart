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
import 'package:jsparser2/javascript_parser.dart';
import "package:parser_error/parser_error.dart";

void main(List<String> args) {
  bool printResolution = (args.length == 2 && args[0] == "--print-resolution");
  if (args.length != 1 && !printResolution) {
    printUsage();
    return;
  }
  File file = new File(args[printResolution ? 1 : 0]);
  file.readAsString().then((String content) {
    (parse(content));
  });
}

dynamic parse(String content) {
  var parser = new JavascriptParser(content);
  var result = parser.parse_Start();
  if(!parser.success) {
    var messages = [];
    for(var error in parser.errors()) {
      messages.add(new ParserErrorMessage(error.message, error.start, error.position));
    }

    var strings = ParserErrorFormatter.format(parser.text, messages);
    print(strings.join("\n"));
    throw new FormatException();
  }

  print(joinAll(result));

  return result;
}

String joinAll(result) {
  String res = '';
  for(var val in result) {
    if(val is String) {
      res += val;
    } else if(val is List && val.isNotEmpty) {
      res += joinAll(val);
    }
  }
  return res;
}

void printUsage() {
  print("Usage: dart jsparser.dart [--print-resolution] <file.js>");
}
