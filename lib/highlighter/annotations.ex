defmodule Highlighter.Annotations do
  alias Highlighter.Annotation

  @start_pos_oob_err :start_pos_out_of_bounds
  @end_pos_oob_err :end_pos_out_of_bounds
  @both_pos_oob_err :start_and_end_pos_out_of_bounds

  def validate(annotations, string) when is_list(annotations) and is_binary(string) do
    all_invalid_annotations = do_validate(annotations, string)

    if Enum.empty?(all_invalid_annotations) do
      {:ok, annotations}
    else
      {:error, all_invalid_annotations}
    end
  end

  defp do_validate(annotations, string) do
    string_length = String.length(string)
    anns_start_pos_oob = Enum.filter(annotations, &start_pos_oob?(&1, string_length))
    anns_end_pos_oob = Enum.filter(annotations, &end_pos_oob?(&1, string_length))
    both_pos_oob = in_both(annotations, anns_end_pos_oob, anns_start_pos_oob)
    anns_start_pos_oob = reject_in(anns_start_pos_oob, both_pos_oob)
    anns_end_pos_oob = reject_in(anns_end_pos_oob, both_pos_oob)
    anns_start_pos_oob = Enum.map(anns_start_pos_oob, &{@start_pos_oob_err, &1})
    anns_end_pos_oob = Enum.map(anns_end_pos_oob, &{@end_pos_oob_err, &1})
    both_pos_oob = Enum.map(both_pos_oob, &{@both_pos_oob_err, &1})

    anns_start_pos_oob ++ anns_end_pos_oob ++ both_pos_oob
  end

  defp end_pos_oob?(%Annotation{end_pos: end_pos}, string_len) when end_pos > string_len, do: true
  defp end_pos_oob?(%Annotation{end_pos: end_pos}, _string_len) when end_pos < 0, do: true
  defp end_pos_oob?(_ann, _string_len), do: false

  defp start_pos_oob?(%Annotation{start_pos: start_pos}, _string_len) when start_pos < 0, do: true

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

  def open_and_close_tag(%Annotation{} = ann) do
    open_tag(ann) <> close_tag(ann)
  end

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
    |> Enum.with_index()
    |> Enum.map(fn {ann, idx} -> Map.put(ann, :orig_idx, idx) end)
    |> Enum.sort(&sort/2)
    |> Enum.with_index()
    |> Enum.map(fn {ann, idx} -> Map.put(ann, :idx, idx) end)
  end

  # If idx is not -1, then it was sorted previously and assigned idx values - sort by idx again
  def sort([%Annotation{idx: idx} | _] = annotations) when idx > -1 and is_list(annotations) do
    Enum.sort_by(annotations, &Map.get(&1, :idx), &<=/2)
  end

  # Sort by start_pos, breaking ties by preferring longer matches
  def sort(%Annotation{} = left, %Annotation{} = right) do
    cond do
      left.start_pos == right.start_pos and
        left.end_pos == right.end_pos and
          left.depth == right.depth ->
        left.orig_idx < right.orig_idx

      left.start_pos == right.start_pos and left.end_pos == right.end_pos ->
        left.depth < right.depth

      left.start_pos == right.start_pos ->
        left.end_pos > right.end_pos

      true ->
        left.start_pos < right.start_pos
    end
  end

  def find_min_start_pos(annotations) when is_list(annotations) do
    annotations
    |> Enum.min(&sort/2, fn -> %Annotation{start_pos: -1} end)
    |> Map.get(:start_pos)
    |> max(0)
  end

  def close_all(annotations) when is_list(annotations) do
    annotations
    |> sort()
    |> Enum.reverse()
    |> Enum.map(&close_tag/1)
    |> Enum.join("")
    |> to_charlist()
  end

  def open_all(annotations) when is_list(annotations) do
    annotations
    |> sort()
    |> Enum.map(&open_tag/1)
    |> Enum.join("")
    |> to_charlist()
  end

  def open_and_close_all(annotations) when is_list(annotations) do
    annotations
    |> sort()
    |> Enum.map(&open_and_close_tag/1)
    |> Enum.join("")
    |> to_charlist()
  end

  def filter_ends_here(annotations, pos) when is_list(annotations) do
    Enum.filter(annotations, &ends_here?(&1, pos))
  end

  def open_tags_starting_here(annotations, pos) when is_list(annotations) do
    annotations
    |> Enum.filter(&starts_here?(&1, pos))
    |> Enum.map(&open_tag/1)
    |> Enum.join("")
  end

  def annotate(string, annotations) when is_binary(string) and is_list(annotations) do
    with {:ok, annotations} <- validate(annotations, string),
         anns <- sort(annotations),
         charlist_with_pos <- string |> to_charlist() |> Enum.with_index() do
      do_annotate(charlist_with_pos, anns)
    else
      {:error, validation_issues} -> {:error, validation_issues}
    end
  end

  defp do_annotate(charlist_with_pos, anns)
       when is_list(charlist_with_pos) and is_list(anns) do
    charlist_with_pos
    |> Enum.reduce(%{open: [], out: [], anns: anns}, &do_annotate(&1, &2))
    |> Map.get(:out)
    |> List.to_string()
  end

  defp do_annotate({char, pos}, %{open: open, out: out, anns: anns})
       when is_list(anns) do
    # Open annotations that begin here
    %{open_and_close: open_and_close, open: traversed_open} = traverse_annotations(anns, pos)

    open = sort(traversed_open ++ open)

    open_charlist = open_all(traversed_open) |> to_charlist()
    open_and_close_charlist = open_and_close_all(open_and_close) |> to_charlist()

    out = out ++ open_and_close_charlist ++ open_charlist

    # Remove any opened annotations from the `anns` list - they're in progress (pending close)
    anns = sort(anns -- open -- open_and_close)

    # Write the character out
    out = out ++ [char]

    # Close annotations that end after the current position:
    #   - Handle overlapping annotations
    #   - We sort the open annotations by their start_pos
    #   - We want to close all annotations ending after the current position AS WELL AS
    #     annotations that overlap this annotation's end, which means it should reopen
    #     after closing it

    # Find annotations that end in the next position
    to_close = Enum.filter(open, &(&1.end_pos == pos + 1))
    open = open -- to_close
    min_start = find_min_start_pos(to_close)

    # Find annotations that overlap annotations closing after this, and that should
    # re-open after it closes
    out =
      if to_close == [] do
        out
      else
        overlaps = Enum.filter(open, &(&1.start_pos > min_start))
        overlap_out = close_all(overlaps)
        out ++ overlap_out
      end

    # Loop through all of the to_close and close them out
    to_close_out = close_all(to_close)
    out = out ++ to_close_out

    out =
      if to_close == [] do
        out
      else
        overlaps = Enum.filter(open, &(&1.start_pos > min_start))
        overlap_out = open_all(overlaps)
        out ++ overlap_out
      end

    %{anns: anns, out: out, open: open}
  end

  def traverse_annotations(anns, pos) do
    init_acc = %{open: [], open_and_close: []}
    Enum.reduce(anns, init_acc, &do_traverse_annotations(&1, &2, pos))
  end

  defp do_traverse_annotations(ann, %{open: open, open_and_close: oac} = acc, pos) do
    cond do
      ann.start_pos == pos and ann.end_pos == pos ->
        %{acc | open_and_close: [ann | oac]}

      ann.start_pos == pos ->
        %{acc | open: sort([ann | open])}

      true ->
        acc
    end
  end
end
