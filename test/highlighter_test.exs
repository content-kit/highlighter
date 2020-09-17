defmodule HighlighterTest do
  use ExUnit.Case

  describe "annotate/2" do
    test "passes through to internal module" do
      assert Highlighter.annotate("abc", []) == "abc"
    end
  end
end
