#!/bin/env awk
# Script to extract make-style documentation comments for various targets in the
# Sparrow build system.
#
# Documentation comments are of the form:
#
#   ## Short one-line summary comment
#   #
#   # Additional descriptive text.
#   target:
#
# Note that the target definition terminates the doc-comment!
#
## Theory of operation
#
# This script operates in two passes: first it accumulates all doc comments from
# the files specified on the command line, and then it looks up the target in
# the `targetname` environment variable for the name of the target to extract
# docs for.
#
# If `targetname` is empty or a target we didn't find, hmm will output a list of
# targets that have doccomments instead.

BEGIN {
  debug = 0;
}

function flush_comment() {
  doc_accumulator = "";
  in_doccomment = 0;
}

# Start of a doc-comment. This enables accumulation of a doc-comment into the
# accumulator in the later patterns.
/^## / {
  in_doccomment = 1;
  doc_accumulator = substr($0, 3);

  doc_filename = ARGV[ARGIND];
  sub(ENVIRON["ROOTDIR"] "/", "", doc_filename);
}

# Continuation of a doc-comment
in_doccomment && /^# / {
  comment = substr($0, 2);
  doc_accumulator = sprintf("%s\n%s", doc_accumulator, comment);
}

# Doc-comment empty line, so we can separate paragraphs.
in_doccomment && /^#$/ {
  doc_accumulator = sprintf("%s\n", doc_accumulator);
}

# Doc-comment proper terminator -- the target name.
in_doccomment && /^[^#]*:/ {
  target = substr($1, 0, index($1, ":") - 1);
  docs[target] = doc_accumulator;
  files[target] = doc_filename;
  flush_comment();
}

END {
  targetname = ENVIRON["targetname"];

  if (targetname in docs) {
    print "";
    print targetname ": (defined in " files[targetname] ")";
    print docs[targetname];
    print "";
    exit(0);
  }

  print "";
  print "Targets available are:";
  print "";
  column = 0;

  # Sort the target list keys into a normal array so we can sort 'em.
  for (target in docs) {
    targets[++j] = target
  }

  asort(targets)

  for (target in targets) {
    target = targets[target]
    printf("%s ", target);
    column += length(target) + 1;
    if (column > 75) {
      print "";
      column = 0;
    }
  }
  print "";

  print "";
  print "To get more information on a target, use 'hmm [target]'"
  print "";
}
