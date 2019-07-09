// Copyright Project Harbor Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package lastx

import "github.com/goharbor/harbor/src/pkg/retention/res"

// Evaluator for evaluating last x days
type Evaluator struct {
	// last x days
	x int
}

// Process the candidates based on the rule definition
func (e *Evaluator) Process(artifacts []*res.Candidate) ([]*res.Candidate, error) {
	return nil, nil
}