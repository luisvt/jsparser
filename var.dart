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

#library("var");

class Var implements Hashable {
  static int varCounter = 0;

  final int varId;
  final String id;
  final bool isGlobal;
  bool isImplicit;
  bool isParam;
  Var(this.id, [this.isGlobal = false,
                this.isImplicit = false,
                this.isParam = false])
      : varId = (varCounter++ & 0x7FFFFFFF);

  bool get isThis() => id == "this";

  int hashCode() => varId;
}


// Note that Interceptors may live in the top-level.
class Interceptor extends Var {
  Var intercepted;
  Dynamic reason;
  Interceptor(String id, this.intercepted, this.reason) : super(id);
}
