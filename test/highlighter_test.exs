defmodule HighlighterTest do
  use ExUnit.Case
  doctest Highlighter

  alias Highlighter.{Annotation, Annotations}

  describe "sorting" do
    test "sorts by starting position" do
      # "dog cat koala" => "<dog>dog</dog> <cat>cat</cat> <koala>koala</koala>
      annotations = [
        %Annotation{start: 9, finish: 13, left: "<koala>", right: "</koala>"},
        %Annotation{start: 1, finish: 3, left: "<dog>", right: "</dog>"},
        %Annotation{start: 5, finish: 7, left: "<cat>", right: "</cat>"}
      ]

      sorted = Annotations.sort(annotations)

      assert sorted == [
               %Annotation{start: 1, finish: 3, left: "<dog>", right: "</dog>"},
               %Annotation{start: 5, finish: 7, left: "<cat>", right: "</cat>"},
               %Annotation{start: 9, finish: 13, left: "<koala>", right: "</koala>"}
             ]
    end

    test "breaks ties by preferring longer matches" do
      annotations = [
        %Annotation{start: 1, finish: 3, left: "<x>", right: "</x>"},
        %Annotation{start: 1, finish: 5, left: "<z>", right: "</z>"},
        %Annotation{start: 1, finish: 4, left: "<y>", right: "</y>"}
      ]

      sorted = Annotations.sort(annotations)

      assert sorted == [
               %Annotation{start: 1, finish: 5, left: "<z>", right: "</z>"},
               %Annotation{start: 1, finish: 4, left: "<y>", right: "</y>"},
               %Annotation{start: 1, finish: 3, left: "<x>", right: "</x>"}
             ]
    end

    test "same range with want_inner specified" do
      annotations = [
        %Annotation{start: 1, finish: 3, left: "<x>", right: "</x>"},
        %Annotation{start: 1, finish: 3, left: "<z>", right: "</z>", want_inner: 2},
        %Annotation{start: 1, finish: 3, left: "<q>", right: "</q>", want_inner: -1},
        %Annotation{start: 1, finish: 3, left: "<y>", right: "</y>", want_inner: 1}
      ]

      sorted = Annotations.sort(annotations)

      assert sorted == [
               %Annotation{start: 1, finish: 3, left: "<q>", right: "</q>", want_inner: -1},
               %Annotation{start: 1, finish: 3, left: "<x>", right: "</x>"},
               %Annotation{start: 1, finish: 3, left: "<y>", right: "</y>", want_inner: 1},
               %Annotation{start: 1, finish: 3, left: "<z>", right: "</z>", want_inner: 2}
             ]
    end
  end
end
