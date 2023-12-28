# Highlighter

<p align="center">
  <picture>
    <img alt="Robot alchemist highlighting text" src="https://github.com/content-kit/highlighter/blob/4b108ec69a35d976ebe2691d57e07f60487d5d87/assets/highlighter.png" width="200">
  </picture>
</p>

Highlighter is an Elixir package which can be used to highlight or
annotate text using a list of annotations.

## Project status

It's early stages for this project and it may not be "production ready"
– for instance, there have been no performance benchmarks or
optimizations. Contributions are welcome!

## Usage

To use Highlighter, invoke `Highlighter.annotate/2` with a string and a
list of `Highlighter.Annotation`'s to apply to that string:

```elixir
test "three annotations (simple words)" do
  dog_annotation = %Highlighter.Annotation{start_pos: 0, end_pos: 3, open: "<woof>", close: "</woof>"}
  cat_annotation = %Highlighter.Annotation{start_pos: 8, end_pos: 11, open: "<meow>", close: "</meow>"}
  cow_annotation = %Highlighter.Annotation{start_pos: 16, end_pos: 19, open: "<moo>", close: "</moo>"}

  annotations = [dog_annotation, cat_annotation, cow_annotation]

  annotated = Highlighter.annotate("dog and cat and cow", annotations)

  assert annotated == "<woof>dog</woof> and <meow>cat</meow> and <moo>cow</moo>"
end
```

## Acknowledgments

### `sourcegraph/annotate`

This project is inspired by
[`annotate`](https://github.com/sourcegraph/annotate), a BSD-3-Clause
licensed Go package developed by Sourcegraph. A copy of the license is
available at:

> [https://github.com/sourcegraph/annotate/blob/master/LICENSE](https://github.com/sourcegraph/annotate/blob/master/LICENSE)

We wish to express our gratitude to Sourcegraph and all the contributors
to the `annotate` Go package, which was a very useful reference for this
Elixir package.

(References to Sourcegraph and its contributors are for credit purposes
only and do not imply any endorsement or promotion.)

## License

Copyright 2020 Content Kit Pty Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at:

> <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
