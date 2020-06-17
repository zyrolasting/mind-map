#lang scribble/manual
@require[@for-label[mind-map
                    racket/base]
                    racket/runtime-path]

@title{Creating Mind Maps in Racket}
@author{Sage Gerard}

@defmodule[mind-map]

Use this collection to leverage a form of note-taking with indented
lines. Here, a @deftech{mind map} is a text document where each line
is an idea. Each idea may be indented to illustrate a composition of
ideas.

@verbatim[#:indent 4]|{
Machine Learning (ML)
  To Evaluate
    ELKI
    TensorFlow
      https://www.tensorflow.org
  Desired approaches
    Supervised
    Reinforcement
}|

@margin-note{@bold{You cannot escape a line break to combine lines.}
This is deliberate, because this format is not meant for writing
complete sentences or paragraphs.}
Here, @litchar{To Evaluate} and @litchar{Desired approaches} belong to
the @litchar{Machine Learning (ML)} idea. Although the example suggests
otherwise, you can have more than one top-level idea in a document.

A line supports a leading mix of tabs and spaces, but an indentation
error will occur if a scope cannot be inferred for a line. The rules
for indentation imitate Python's, such that a line with a lower level
of indentation is expected to have the same number of tabs and spaces
as a prior line in the same implied scope. See
@racket[exn:fail:mind-map:indent].


@section{Mind Map Language}

Write @litchar{#lang mind-map} at the top of the previous example.
Save it as @racket{example.rkt}, then @racket[require] it in a
REPL. You will get a @racket[thoughts] identifier bound to a
list. That list represents the parse tree of a mind map.

@racketinput[(require "example.rkt")]
@racketinput[thoughts]
@racketresult[
'(("Machine Learning (ML)"
                ("To Evaluate"
                 ("ELKI")
                 ("TensorFlow" ("https://www.tensorflow.org")))
                ("Desired approaches" ("Supervised") ("Reinforcement"))))]

In DrRacket, you can render @racket[thoughts] as a pict.

@racketresult[(thoughts->pict thoughts)]

@(define-runtime-path img "rendered-pict.png")
@image[img]


@section{API}

@defproc[(read-thoughts [in input-port?]) list?]{
Consumes all text from the input port and returns a list representing
a parse tree of notes.

Any trailing or leading whitespace is trimmed from a line.

This assumes there is no leading @litchar{#lang} line.
}

@defproc[(thoughts->digraph-data [thoughts list?]) (values list? list?)]{
Returns two lists of directed graph data. The first list contains
vertices. The second contains edges.

An element of the vertex list is a pair. The @racket[car] of the pair
is a non-negative integer representing the vertex ID. The @racket[cdr]
of the pair is the string label for the vertex.

An element of the edge list is a pair of vertex IDs, such that the
@racket[car]'s vertex points to the @racket[cdr]'s.

@racketinput[(thoughts->digraph-data thoughts)]
@racketresult[
'((0 . "Machine Learning")
            (1 . "To Evaluate")
            (2 . "ELKI")
            (3 . "TensorFlow")
            (4 . "https://www.tensorflow.org")
            (5 . "Desired approaches")
            (6 . "Supervised")
            (7 . "Reinforcement"))]
@racketresult[
'((5 . 7) (5 . 6) (0 . 5) (3 . 4) (1 . 3) (1 . 2) (0 . 1))]
}

@defproc[(thoughts->pict [thoughts list?]) pict?]{
Renders thoughts as a @racket[pict].
}

@defstruct*[(exn:fail:mind-map:indent exn:fail) ([lineno exact-nonnegative-integer?])]{
Informs the user of a line with an invalid leading sequence of tabs or spaces.

Consider the following document, where @litchar{>} represents a tab.

@verbatim|{
Trunk
  Branch
    Leaf
    Leaf
> Branch
  Branch
    Leaf
      Caterpillar
  Branch
}|

The @litchar{Branch} with a leading tab raises an indentation error,
because the transition from @litchar{Leaf} to @litchar{Branch} implies
a change in scope, but there is no prior scope at @litchar{Branch}-level
with the same leading whitespace.

The indentation error can be fixed by replacing the tab with a space,
or by replacing one space with a tab in all indented lines.
}


@section{Project Information}

@(define srclink "https://github.com/zyrolasting/mind-map")

Source Code: @hyperlink[srclink srclink]

Thanks to Hadi Moshayedi for use of the @tt{racket-graphviz} package in @racket[thoughts->pict].
