module Rugged
  # Monkeypatch Repository to add the merge method found in pygit2
  class Repository
    # Merges the given id into HEAD.

    # Merges the given commit(s) into HEAD, writing the results into the working directory.
    # Any changes are staged for commit and any conflicts are written to the index.
    # Callers should inspect the repository's index after this completes,
    # resolve any conflicts and prepare a commit.
    #
    # Parameters:
    # id
    #     The id to merge into HEAD
    #
    # favor
    #     How to deal with file-level conflicts. Can be one of
    #
    #     * normal (default). Conflicts will be preserved.
    #     * ours. The "ours" side of the conflict region is used.
    #     * theirs. The "theirs" side of the conflict region is used.
    #     * union. Unique lines from each side will be used.
    #
    #     For all but NORMAL, the index will not record a conflict.
    #
    # flags
    #     A dict of str: bool to turn on or off functionality while merging.
    #     If a key is not present, the default will be used. The keys are:
    #
    #     * find_renames. Detect file renames. Defaults to True.
    #     * fail_on_conflict. If a conflict occurs, exit immediately instead
    #       of attempting to continue resolving conflicts.
    #     * skip_reuc. Do not write the REUC extension on the generated index.
    #     * no_recursive. If the commits being merged have multiple merge
    #       bases, do not build a recursive merge base (by merging the
    #       multiple merge bases), instead simply use the first base.
    #
    # file_flags
    #     A dict of str: bool to turn on or off functionality while merging.
    #     If a key is not present, the default will be used. The keys are:
    #
    #     * standard_style. Create standard conflicted merge files.
    #     * diff3_style. Create diff3-style file.
    #     * simplify_alnum. Condense non-alphanumeric regions for simplified
    #       diff file.
    #     * ignore_whitespace. Ignore all whitespace.
    #     * ignore_whitespace_change. Ignore changes in amount of whitespace.
    #     * ignore_whitespace_eol. Ignore whitespace at end of line.
    #     * patience. Use the "patience diff" algorithm
    #     * minimal. Take extra time to find minimal diff
    def merge
      raise TypeError("expected oid (string or <Oid>) got #{type(id)}") \
        if not isinstance(id, (str, Oid))

      id = self[id].id
      c_id = ffi.new("git_oid *")
      ffi.buffer(c_id)[:] = id.raw[:]

      merge_opts = self._merge_options(favor, flags=flags or {}, file_flags=file_flags or {})

      checkout_opts = ffi.new("git_checkout_options *")
      C.git_checkout_options_init(checkout_opts, 1)
      checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING

      commit_ptr = ffi.new("git_annotated_commit **")
      err = C.git_annotated_commit_lookup(commit_ptr, self._repo, c_id)
      check_error(err)

      err = C.git_merge(self._repo, commit_ptr, 1, merge_opts, checkout_opts)
      C.git_annotated_commit_free(commit_ptr[0])
      check_error(err)
    end
  end
end
