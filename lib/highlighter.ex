defmodule Highlighter do
  @moduledoc """
  Documentation for `Highlighter`.
  """

  defdelegate annotate(string, annotations), to: Highlighter.Annotations
end
