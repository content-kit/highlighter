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

  describe "starts_after?/2" do
    test "returns true if the annotation start position is after the position arg" do
      annotation = %Annotation{start_pos: 2, end_pos: 6, open: "<dog>", close: "</dog>"}
      assert Annotations.starts_after?(annotation, 1)
    end

    test "returns false if the annotation start position is not after the position arg" do
      annotation = %Annotation{start_pos: 3, end_pos: 6, open: "<dog>", close: "</dog>"}
      refute Annotations.starts_after?(annotation, 3)
      refute Annotations.starts_after?(annotation, 4)
    end
  end

  describe "ends_here?/2" do
    test "returns true if the annotation ends immediately at the position arg" do
      annotation = %Annotation{start_pos: 2, end_pos: 3, open: "<dog>", close: "</dog>"}
      assert Annotations.ends_here?(annotation, 3)
    end

    test "returns false if the annoation end is not immediately at the position arg" do
      annotation = %Annotation{start_pos: 2, end_pos: 3, open: "<dog>", close: "</dog>"}
      refute Annotations.ends_here?(annotation, 2)
      refute Annotations.ends_here?(annotation, 4)
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

  describe "close_all/1" do
    test "closes all annoations in reverse idx order" do
      annotations = [
        %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>"},
        %Annotation{start_pos: 9, end_pos: 13, open: "<koala>", close: "</koala>"},
        %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>"}
      ]

      sorted_annotations = Annotations.sort(annotations)

      assert Annotations.close_all(sorted_annotations) == "</koala></cat></dog>"
    end
  end

  describe "filter_ends_here/2" do
    setup do
      dog_ann = %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>"}
      koala_ann = %Annotation{start_pos: 9, end_pos: 13, open: "<koala>", close: "</koala>"}
      cat_ann = %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>"}

      annotations = [dog_ann, koala_ann, cat_ann]

      %{dog_ann: dog_ann, koala_ann: koala_ann, cat_ann: cat_ann, annotations: annotations}
    end

    test "returns a list of annotations which end at the position arg",
         %{annotations: annotations, koala_ann: koala_ann} do
      assert Annotations.filter_ends_here(annotations, 13) == [koala_ann]
      assert Annotations.filter_ends_here(annotations, 14) == []
    end

    test "returns an empty list when no annotations end at the position arg",
         %{annotations: annotations} do
      assert Annotations.filter_ends_here(annotations, 14) == []
    end

    test "returns an empty list when the list of annotations is also empty" do
      assert Annotations.filter_ends_here([], 0) == []
      assert Annotations.filter_ends_here([], 13) == []
    end
  end

  describe "validate/2" do
    test "returns ok tuple with annotations if all are valid" do
      annotations = [
        %Annotation{start_pos: 9, end_pos: 13, open: "<koala>", close: "</koala>"},
        %Annotation{start_pos: 1, end_pos: 3, open: "<dog>", close: "</dog>"},
        %Annotation{start_pos: 5, end_pos: 7, open: "<cat>", close: "</cat>"}
      ]

      assert {:ok, annotations} = Annotations.validate(annotations, "dog cat koala")
    end

    test "returns error tuple if annotations are invalid" do
      ann1 = %Annotation{start_pos: 4, end_pos: 5, open: "<oops>", close: "</oops>"}
      ann2 = %Annotation{start_pos: 1, end_pos: 4, open: "<oops>", close: "</oops>"}
      ann3 = %Annotation{start_pos: 0, end_pos: 2, open: "<oops>", close: "</oops>"}

      annotations = [ann1, ann2, ann3]

      assert {:error, issues} = Annotations.validate(annotations, "abc")

      assert Enum.count(issues) == 3

      assert {:start_and_end_pos_out_of_bounds, ann1} in issues
      assert {:end_pos_out_of_bounds, ann2} in issues
      assert {:start_pos_out_of_bounds, ann3} in issues
    end
  end

  describe "open_tags_starting_here/2" do
    test "opens (and immediately closes zero-length) tags starting at the position arg" do
      ann1 = %Annotation{start_pos: 4, end_pos: 5, open: "<1>", close: "</1>"}
      ann2 = %Annotation{start_pos: 1, end_pos: 4, open: "<2>", close: "</2>"}
      ann3 = %Annotation{start_pos: 0, end_pos: 2, open: "<3>", close: "</3>"}
      ann4 = %Annotation{start_pos: 4, end_pos: 4, open: "<4>", close: "</4>"}

      annotations = Annotations.sort([ann1, ann2, ann3, ann4])

      assert Annotations.open_tags_starting_here(annotations, 4) == "<1><4></4>"
    end

    test "returns empty string for empty list of annotations" do
      assert Annotations.open_tags_starting_here([], 0) == ""
    end

    test "returns empty string if no annotations start at position arg" do
      ann1 = %Annotation{start_pos: 4, end_pos: 5, open: "<nope>", close: "</nope>"}
      ann2 = %Annotation{start_pos: 1, end_pos: 4, open: "<nope>", close: "</nope>"}
      ann3 = %Annotation{start_pos: 0, end_pos: 2, open: "<nope>", close: "</nope>"}

      annotations = Annotations.sort([ann1, ann2, ann3, ann3])

      refute Annotations.open_tags_starting_here(annotations, 1) == ""
      assert Annotations.open_tags_starting_here(annotations, 2) == ""
      assert Annotations.open_tags_starting_here(annotations, 3) == ""
      refute Annotations.open_tags_starting_here(annotations, 4) == ""
      assert Annotations.open_tags_starting_here(annotations, 5) == ""
    end
  end

  describe "annotate/2" do
    test "one annotation (simple)" do
      dog_annotation = %Annotation{start_pos: 1, end_pos: 3, open: "<woof>", close: "</woof>"}

      annotated = Annotations.annotate("dog", List.wrap(dog_annotation))

      assert annotated == "<woof>dog</woof>"
    end

    test "two annotations (simple)" do
      dog_annotation = %Annotation{start_pos: 1, end_pos: 3, open: "<woof>", close: "</woof>"}
      cat_annotation = %Annotation{start_pos: 9, end_pos: 11, open: "<meow>", close: "</meow>"}
      annotations = [dog_annotation, cat_annotation]

      annotated = Annotations.annotate("dog and cat", annotations)

      assert annotated == "<woof>dog</woof> and <meow>cat</meow>"
    end

    test "three annotations (simple)" do
      dog_annotation = %Annotation{start_pos: 1, end_pos: 3, open: "<woof>", close: "</woof>"}
      cat_annotation = %Annotation{start_pos: 9, end_pos: 11, open: "<meow>", close: "</meow>"}
      cow_annotation = %Annotation{start_pos: 17, end_pos: 19, open: "<moo>", close: "</moo>"}

      annotations = [dog_annotation, cat_annotation, cow_annotation]

      annotated = Annotations.annotate("dog and cat and cow", annotations)

      assert annotated == "<woof>dog</woof> and <meow>cat</meow> and <moo>cow</moo>"
    end

    test "overlapping annotations (simple)" do
      annotations = [
        %Annotation{start_pos: 1, end_pos: 2, open: "<X>", close: "</X>"},
        %Annotation{start_pos: 2, end_pos: 3, open: "<Y>", close: "</Y>"}
      ]

      annotated = Annotations.annotate("abc", annotations)

      unexpected_non_overlapping = "<X>a<Y>b</X>c</Y>"
      expected_overlapping = "<X>a<Y>b</Y></X><Y>c</Y>"

      refute annotated == unexpected_non_overlapping
      assert annotated == expected_overlapping
    end

    test "overlapping annotations (simple, double)" do
      annotations = [
        %Annotation{start_pos: 1, end_pos: 2, open: "<X1>", close: "</X1>", want_inner: -1},
        %Annotation{start_pos: 1, end_pos: 2, open: "<X2>", close: "</X2>"},
        %Annotation{start_pos: 2, end_pos: 3, open: "<Y1>", close: "</Y1>", want_inner: -1},
        %Annotation{start_pos: 2, end_pos: 3, open: "<Y2>", close: "</Y2>"}
      ]

      annotated = Annotations.annotate("abc", annotations)

      expected = "<X1><X2>a<Y1><Y2>b</Y2></Y1></X2></X1><Y1><Y2>c</Y2></Y1>"

      assert annotated == expected
    end
  end
end
