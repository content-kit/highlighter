defmodule Highlighter.Annotations do
  alias Highlighter.Annotation

  @start_pos_oob_err :start_pos_out_of_bounds
  @end_pos_oob_err :end_pos_out_of_bounds
  @both_pos_oob_err :start_and_end_pos_out_of_bounds

  def validate(annotations, string) when is_list(annotations) and is_binary(string) do
    with string_length <- String.length(string),
         anns_start_pos_oob <- Enum.filter(annotations, &start_pos_oob?(&1, string_length)),
         anns_end_pos_oob <- Enum.filter(annotations, &end_pos_oob?(&1, string_length)),
         both_pos_oob <- in_both(annotations, anns_end_pos_oob, anns_start_pos_oob),
         anns_start_pos_oob <- reject_in(anns_start_pos_oob, both_pos_oob),
         anns_end_pos_oob <- reject_in(anns_end_pos_oob, both_pos_oob),
         anns_start_pos_oob <- Enum.map(anns_start_pos_oob, &{@start_pos_oob_err, &1}),
         anns_end_pos_oob <- Enum.map(anns_end_pos_oob, &{@end_pos_oob_err, &1}),
         both_pos_oob <- Enum.map(both_pos_oob, &{@both_pos_oob_err, &1}),
         all_invalid_annotations <- anns_start_pos_oob ++ anns_end_pos_oob ++ both_pos_oob do
      if Enum.empty?(all_invalid_annotations) do
        {:ok, annotations}
      else
        {:error, all_invalid_annotations}
      end
    end
  end

  defp end_pos_oob?(%Annotation{end_pos: end_pos}, string_len) when end_pos > string_len, do: true
  defp end_pos_oob?(%Annotation{end_pos: end_pos}, _string_len) when end_pos < 1, do: true
  defp end_pos_oob?(_ann, _string_len), do: false

  defp start_pos_oob?(%Annotation{start_pos: start_pos}, _string_len) when start_pos < 1, do: true

  defp start_pos_oob?(%Annotation{start_pos: start_pos}, string_len)
       when start_pos > string_len,
       do: true

  defp start_pos_oob?(_ann, _string_len), do: false

  defp in_both(annotations, list1, list2) do
    Enum.filter(annotations, fn ann -> Enum.member?(list1, ann) and Enum.member?(list2, ann) end)
  end

  defp reject_in(annotations, reject_if_in_this_list) do
    Enum.reject(annotations, &Enum.member?(reject_if_in_this_list, &1))
  end

  def open_tag(%Annotation{open: open}), do: open
  def close_tag(%Annotation{close: close}), do: close

  def starts_here?(%Annotation{start_pos: start_pos}, pos) when start_pos == pos, do: true
  def starts_here?(_ann, _pos), do: false

  def starts_and_ends_here?(%Annotation{start_pos: start_pos, end_pos: end_pos}, pos) do
    start_pos == end_pos && end_pos == pos
  end

  def starts_after?(%Annotation{start_pos: start_pos}, pos) when start_pos > pos, do: true
  def starts_after?(_ann, _pos), do: false

  def ends_here?(%Annotation{end_pos: end_pos}, pos) when pos == end_pos, do: true
  def ends_here?(_ann, _pos), do: false

  def sort([]), do: []

  # If idx is -1, then the list has not been sorted before
  def sort([%Annotation{idx: -1} | _] = annotations) when is_list(annotations) do
    annotations
    |> Enum.reverse()
    |> Enum.sort(&sort/2)
    |> Enum.with_index()
    |> Enum.map(fn {ann, idx} -> Map.put(ann, :idx, idx) end)
  end

  # If idx is not -1, then it was sorted previously and assigned indx values - sort by idx again
  def sort([%Annotation{idx: idx} | _] = annotations) when idx > -1 and is_list(annotations) do
    Enum.sort_by(annotations, &Map.get(&1, :idx), &<=/2)
  end

  # Sort by start_pos, breaking ties by preferring longer matches
  def sort(%Annotation{} = left, %Annotation{} = right) do
    cond do
      left.start_pos == right.start_pos && left.end_pos == right.end_pos ->
        left.depth < right.depth

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

  def close_all(sorted_annotations) when is_list(sorted_annotations) do
    sorted_annotations
    |> Enum.sort_by(&Map.get(&1, :idx), &<=/2)
    |> Enum.reverse()
    |> Enum.map(&close_tag/1)
    |> Enum.join("")
  end

  def open_all(sorted_annotations) when is_list(sorted_annotations) do
    sorted_annotations
    |> Enum.sort_by(&Map.get(&1, :idx), &<=/2)
    |> Enum.map(&open_tag/1)
    |> Enum.join("")
  end

  def filter_ends_here(annotations, pos) when is_list(annotations) do
    Enum.filter(annotations, &ends_here?(&1, pos))
  end

  def open_tags_starting_here(annotations, pos) when is_list(annotations) do
    annotations
    |> Enum.filter(&(starts_here?(&1, pos) or starts_and_ends_here?(&1, pos)))
    |> Enum.map(&open_and_maybe_close_tag(&1, pos))
    |> Enum.join("")
  end

  defp open_and_maybe_close_tag(%Annotation{} = annotation, pos) do
    if starts_and_ends_here?(annotation, pos) do
      open_tag(annotation) <> close_tag(annotation)
    else
      open_tag(annotation)
    end
  end

  def annotate(string, annotations) when is_binary(string) and is_list(annotations) do
    with {:ok, annotations} <- validate(annotations, string),
         anns <- sort(annotations),
         charlist_with_pos <- string |> to_charlist() |> Enum.with_index(1) do
      do_annotate(charlist_with_pos, anns)
    else
      {:error, validation_issues} -> {:error, validation_issues}
    end
  end

  defp do_annotate(charlist_with_pos, anns)
       when is_list(charlist_with_pos) and is_list(anns) do
    charlist_with_pos
    |> Enum.reduce(%{open: MapSet.new(), out: [], anns: anns}, &do_annotate(&1, &2))
    |> Map.get(:out)
    |> Enum.reverse()
    |> List.to_string()
  end

  defp do_annotate({char_int, char_pos}, %{open: open, out: out, anns: anns})
       when is_list(anns) do
    # IO.inspect(List.to_string([char_int]), label: "-- char")

    # 1. opening tags
    current_open_anns = Enum.filter(anns, &starts_here?(&1, char_pos))
    current_open_tags_str = open_tags_starting_here(anns, char_pos)
    current_open_tags_charlist = to_charlist(current_open_tags_str)

    updated_open_anns = MapSet.union(open, MapSet.new(current_open_anns))
    updated_open_anns_list = MapSet.to_list(updated_open_anns)

    close_anns = Enum.filter(updated_open_anns_list, &ends_here?(&1, char_pos))
    close_tags_str = close_all(close_anns)
    close_tags_charlist = to_charlist(close_tags_str)

    min_start = find_min_start_pos(updated_open_anns_list)
    overlaps = Enum.filter(updated_open_anns_list, &(&1.start_pos > min_start))
    overlaps_close_tags_str = close_all(overlaps)
    overlaps_close_tags_charlist = to_charlist(overlaps_close_tags_str)
    overlaps_open_tags_str = open_all(overlaps)
    overlaps_open_tags_charlist = to_charlist(overlaps_open_tags_str)

    current_out = [
      current_open_tags_charlist,
      [char_int],
      overlaps_close_tags_charlist,
      close_tags_charlist,
      overlaps_open_tags_charlist
    ]

    updated_out = [current_out | out]

    updated_open_anns = MapSet.difference(updated_open_anns, MapSet.new(close_anns))

    updated_anns =
      MapSet.difference(MapSet.new(anns), MapSet.new(updated_open_anns))
      |> MapSet.to_list()
      |> sort()

    %{
      out: updated_out,
      open: updated_open_anns,
      anns: updated_anns
    }
  end
end
