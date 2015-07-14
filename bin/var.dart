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

library variable;

class Var {
  final String id;
  final bool isGlobal;
  final bool isImplicit;
  final bool isParam;

  const Var(this.id, {isGlobal: false,
                isImplicit: false,
                isParam: false})
      : this.isGlobal = isGlobal,
        this.isImplicit = isImplicit,
        this.isParam = isParam;

  bool get isThis => id == "this";
  bool get isOperator => false;
}

const PREFIX_PLUS = const Operator("prefix+");
const PREFIX_MINUS = const Operator("prefix-");
const PREFIX_PLUS_PLUS = const Operator("prefix++");
const PREFIX_MINUS_MINUS = const Operator("prefix--");

const OPERATORS = const [
    PREFIX_PLUS,
    PREFIX_MINUS,
    PREFIX_PLUS_PLUS,
    PREFIX_MINUS_MINUS,
    const Operator("delete"),
    const Operator("void"),
    const Operator("typeof"),
    const Operator("||"),
    const Operator("&&"),
    const Operator("|"),
    const Operator("^"),
    const Operator("&"),
    const Operator("=="),
    const Operator("!="),
    const Operator("==="),
    const Operator("!=="),
    const Operator("<"),
    const Operator(">"),
    const Operator("<="),
    const Operator(">="),
    const Operator("instanceof"),
    const Operator("in"),
    const Operator("<<"),
    const Operator(">>"),
    const Operator(">>>"),
    const Operator("+"),
    const Operator("-"),
    const Operator("*"),
    const Operator("/"),
    const Operator("%"),
];

class Operator extends Var {
  const Operator(String id) : super(id, isGlobal: true);

  bool get isOperator => true;
}

// Note that Interceptors may live in the top-level.
class Interceptor extends Var {
  Var intercepted;
  dynamic reason;
  Interceptor(String id, this.intercepted, this.reason) : super(id);
}
