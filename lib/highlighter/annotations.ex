defmodule Highlighter.Annotations do
  alias Highlighter.Annotation

  def open_tag(%Annotation{open: open}), do: open
  def close_tag(%Annotation{close: close}), do: close

  def starts_here?(%Annotation{start_pos: start_pos}, pos) when start_pos == pos, do: true
  def starts_here?(_ann, _pos), do: false

  def starts_and_ends_here?(%Annotation{start_pos: start_pos, end_pos: end_pos}, pos) do
    start_pos == end_pos && end_pos == pos
  end

  def ends_after?(%Annotation{end_pos: end_pos}, pos) when pos + 1 == end_pos, do: true
  def ends_after?(_ann, _pos), do: false

  def sort(annotations) when is_list(annotations) do
    annotations
    |> Enum.sort(&sort/2)
    |> Enum.with_index()
    |> Enum.map(fn {ann, idx} -> Map.put(ann, :idx, idx) end)
  end

  # Sort by start_pos, breaking ties by preferring longer matches
  def sort(%Annotation{} = left, %Annotation{} = right) do
    cond do
      left.start_pos == right.start_pos && left.end_pos == right.end_pos ->
        left.want_inner < right.want_inner

      left.start_pos == right.start_pos ->
        left.end_pos > right.end_pos

      true ->
        left.start_pos < right.start_pos
    end
  end

  def find_min_start_pos(annotations) when is_list(annotations) do
    annotations
    |> Enum.min(&sort/2, fn -> %Annotation{start_pos: 0} end)
    |> Map.get(:start_pos)
  end

  # def annotate(string, annotations) when is_binary(string) and is_list(annotations) do
  #   sorted_anns = sort(annotations)
  #   charlist_with_pos = string |> String.to_charlist() |> Enum.with_index(1)

  #   do_annotate(charlist_with_pos, sorted_anns)
  # end

  # defp do_annotate(charlist_with_pos, sorted_anns) do
  # end
end
