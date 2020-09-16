defmodule Highlighter.Annotations do
  alias Highlighter.Annotation

  def open_tag(%Annotation{open: open}), do: open
  def close_tag(%Annotation{close: close}), do: close

  def sort(annotations) when is_list(annotations) do
    annotations
    |> Enum.sort(&do_sort/2)
    |> Enum.with_index()
    |> Enum.map(fn {ann, idx} -> Map.put(ann, :idx, idx) end)
  end

  # Sort by start_pos, breaking ties by preferring longer matches
  defp do_sort(%Annotation{} = left, %Annotation{} = right) do
    cond do
      left.start_pos == right.start_pos && left.end_pos == right.end_pos ->
        left.want_inner < right.want_inner

      left.start_pos == right.start_pos ->
        left.end_pos > right.end_pos

      true ->
        left.start_pos < right.start_pos
    end
  end

  # def annotate(string, annotations) when is_binary(string) and is_list(annotations) do
  #   sorted_anns = sort(annotations)
  #   charlist_with_pos = string |> String.to_charlist() |> Enum.with_index(1)

  #   do_annotate(charlist_with_pos, sorted_anns)
  # end

  # defp do_annotate(charlist_with_pos, sorted_anns) do
  # end
end
