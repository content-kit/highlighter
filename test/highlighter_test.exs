defmodule HighlighterTest do
  use ExUnit.Case
  doctest Highlighter

  alias Highlighter.{Annotation, Annotations}

  describe "sort/1" do
    test "sorts by start_pos" do
      # "dog cat koala" => "<dog>dog</dog> <cat>cat</cat> <koala>koala</koala>
      annotations = [
        %Annotation{start_pos: 9, end_pos: 13, open: "<koala>", close: "</koala>"},
        %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>"},
        %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>"}
      ]

      sorted = Annotations.sort(annotations)

      assert sorted == [
               %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>", idx: 0},
               %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>", idx: 1},
               %Annotation{start_pos: 9, end_pos: 13, open: "<koala>", close: "</koala>", idx: 2}
             ]
    end

    test "breaks ties by preferring longer matches" do
      annotations = [
        %Annotation{start_pos: 1, end_pos: 3, open: "<x>", close: "</x>"},
        %Annotation{start_pos: 1, end_pos: 5, open: "<z>", close: "</z>"},
        %Annotation{start_pos: 1, end_pos: 4, open: "<y>", close: "</y>"}
      ]

      sorted = Annotations.sort(annotations)

      assert sorted == [
               %Annotation{start_pos: 1, end_pos: 5, open: "<z>", close: "</z>", idx: 0},
               %Annotation{start_pos: 1, end_pos: 4, open: "<y>", close: "</y>", idx: 1},
               %Annotation{start_pos: 1, end_pos: 3, open: "<x>", close: "</x>", idx: 2}
             ]
    end

    test "same range with want_inner specified" do
      annotations = [
        %Annotation{start_pos: 1, end_pos: 3, open: "<x>", close: "</x>", idx: 0},
        %Annotation{start_pos: 1, end_pos: 3, open: "<z>", close: "</z>", want_inner: 2, idx: 1},
        %Annotation{start_pos: 1, end_pos: 3, open: "<q>", close: "</q>", want_inner: -1, idx: 2},
        %Annotation{start_pos: 1, end_pos: 3, open: "<y>", close: "</y>", want_inner: 1, idx: 3}
      ]

      sorted = Annotations.sort(annotations)

      expected = [
        %Annotation{start_pos: 1, end_pos: 3, open: "<q>", close: "</q>", want_inner: -1, idx: 0},
        %Annotation{start_pos: 1, end_pos: 3, open: "<x>", close: "</x>", idx: 1},
        %Annotation{start_pos: 1, end_pos: 3, open: "<y>", close: "</y>", want_inner: 1, idx: 2},
        %Annotation{start_pos: 1, end_pos: 3, open: "<z>", close: "</z>", want_inner: 2, idx: 3}
      ]

      assert sorted == expected
    end
  end

  describe "open_tag/1" do
    test "returns the opening tag" do
      annotation = %Annotation{open: "<a>", close: "</a>"}
      assert Annotations.open_tag(annotation) == "<a>"
    end
  end

  describe "close_tag/1" do
    test "returns the closing tag" do
      annotation = %Annotation{open: "<a>", close: "</a>"}
      assert Annotations.close_tag(annotation) == "</a>"
    end
  end

  # describe "annotate/2" do
  #   test "one annotation" do
  #     dog_annotation = %Annotation{start_pos: 1, end_pos: 3, open: "<woof>", close: "</woof>"}

  #     annotated = Annotations.annotate("dog", List.wrap(dog_annotation))

  #     assert annotated == "<woof>dog</woof>"
  #   end
  # end
end
