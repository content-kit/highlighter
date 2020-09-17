defmodule Highlighter.Annotation do
  defstruct start_pos: 0, end_pos: 0, open: "", close: "", depth: 0, idx: -1, nowrap?: false
end
