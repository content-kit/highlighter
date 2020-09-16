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

  describe "starts_here?/2" do
    test "returns true if the annotation start position matches the position arg" do
      annotation = %Annotation{start_pos: 3, end_pos: 6, open: "<dog>", close: "</dog>"}
      assert Annotations.starts_here?(annotation, 3)
    end

    test "returns false if the annotation start position does not match the position arg" do
      annotation = %Annotation{start_pos: 3, end_pos: 6, open: "<dog>", close: "</dog>"}
      refute Annotations.starts_here?(annotation, 1)
    end
  end

  describe "starts_and_ends_here?/2" do
    test "returns true if the annotation starting and ending positions match the position arg" do
      annotation = %Annotation{start_pos: 3, end_pos: 3, open: "<dog>", close: "</dog>"}
      assert Annotations.starts_and_ends_here?(annotation, 3)
    end

    test "returns false if the annotation starting or ending positions differ from position arg" do
      annotation = %Annotation{start_pos: 3, end_pos: 4, open: "<dog>", close: "</dog>"}
      refute Annotations.starts_and_ends_here?(annotation, 3)

      annotation = %Annotation{start_pos: 2, end_pos: 3, open: "<dog>", close: "</dog>"}
      refute Annotations.starts_and_ends_here?(annotation, 3)

      annotation = %Annotation{start_pos: 3, end_pos: 3, open: "<dog>", close: "</dog>"}
      refute Annotations.starts_and_ends_here?(annotation, 4)
    end
  end

  describe "ends_after?/2" do
    test "returns true if the annotation ends immediately after the position arg" do
      annotation = %Annotation{start_pos: 2, end_pos: 3, open: "<dog>", close: "</dog>"}
      assert Annotations.ends_after?(annotation, 2)
    end

    test "returns false if the annoation end is not immediately after the position arg" do
      annotation = %Annotation{start_pos: 2, end_pos: 3, open: "<dog>", close: "</dog>"}
      refute Annotations.ends_after?(annotation, 3)
    end
  end

  describe "find_min_start_pos/1" do
    test "returns the lowest start position given a list of annotations" do
      annotations = [
        %Annotation{start_pos: 9, end_pos: 13, open: "<koala>", close: "</koala>"},
        %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>"},
        %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>"}
      ]

      assert Annotations.find_min_start_pos(annotations) == 1
    end

    test "returns the lowest start position given a list of annotations with multiple matches" do
      annotations = [
        %Annotation{start_pos: 1, end_pos: 13, open: "<koala>", close: "</koala>"},
        %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>"},
        %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>"}
      ]

      assert Annotations.find_min_start_pos(annotations) == 1
    end

    test "returns zero when list is empty" do
      assert Annotations.find_min_start_pos([]) == 0
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
