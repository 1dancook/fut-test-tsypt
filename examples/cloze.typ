#import "../lib.typ": *



= Cloze Examples


== Single Sentence Cloze Items

Cloze items are indicated with simple syntax, surrounding the cloze item with curly brackets, i.e. `{cloze item}`:

```typst
#Cloze("This is a {cloze} sentence. There can be {many} cloze items.")
```

Results in:
#Cloze("This is a {cloze} sentence. There can be {many} cloze items.")

By default, the solution is hidden.


== Longer Passages: use more parameters

Longer passages might require a few features:
- multiple cloze items
- question numbering beside blanks
- a list of solutions visible to select from
- any number of detractor(s)

These are made possible with several parameters apart from applying cloze syntax to the text:
- show_solutions: "top" or "left"
- detractor_list -- use a str, int, or array
- detractors -- limit the number of detractors
- show_question_numbers -- shows the question numbers beside the cloze blanks

#let cloze_passage = "The {scientist} carefully recorded the results of the {experiment}, noting even the slightest variations in temperature. As the {data} accumulated, patterns began to emerge that challenged existing {theories}. Despite the late hour, she remained focused, driven by a sense of {curiosity} and purpose."


=== Example: `show_solutions: "top"`


#Cloze(cloze_passage, show_solutions: "top")


=== Example: `show_solutions: "left"`

#Cloze(cloze_passage, show_solutions: "left")


=== Example: `show_solutions: "left"` with `show_question_numbers: true`

This example has one detractor added.

#Cloze(cloze_passage, detractor_list: "detractor", show_solutions: "left", show_question_numbers: true)


=== Example: Explicit `show_solutions: "hidden"` when there are multiple solutions

#Cloze(cloze_passage, show_solutions: "hidden", show_question_numbers: true)



== Other Considerations

It is possible to have an empty cloze item, and a blank line will still be used for entry. The likely use case for this is a single sentence item:

#Question[#Cloze("This is a {} sentence.")]


=== Explicitly display detractors using `show_solutions`


#Question(
  Cloze(
    "The {scientist} carefully recorded the results of the {experiment}, noting even the slightest variations in temperature.",
    detractor_list: "detractor",
  ),
)

#Question[
  #Cloze(
    "The {scientist} carefully recorded the results of the {experiment}, noting even the slightest variations in temperature.",
    detractor_list: "detractor",
    show_solutions: "left",
  )
]
