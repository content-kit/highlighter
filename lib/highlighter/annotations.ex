defmodule Highlighter.Annotations do
  alias Highlighter.Annotation

  def sort(annotations) when is_list(annotations) do
    Enum.sort(annotations, &do_sort/2)
  end

  # Sort by start position, breaking ties by preferring longer matches
  defp do_sort(%Annotation{} = left, %Annotation{} = right) do
    cond do
      left.start == right.start && left.finish == right.finish ->
        left.want_inner < right.want_inner

      left.start == right.start ->
        left.finish > right.finish

      true ->
        left.start < right.start
    end
  end
end
