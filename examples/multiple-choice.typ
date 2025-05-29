#import "../lib.typ": *


Some examples of how to use `MultipleChoice`


+ #[Usually one solution is provided as a string, integer, or text (context) type:
    #MultipleChoice("one solution", ("A", "B", 58))
  ]

+ #[Multiple solutions are possible with an array:
    #MultipleChoice(("A", "B", "C"), ("D", "E", "F"))
  ]

+ #[Multiple solutions but randomly use only one of them (or any limit):
    #MultipleChoice(("A", "B", "C"), ("D", "E", "F"), solutions: 1)
    Note: multiple detractors can be provided and also limited.
  ]

+ #[`text` items (either solutions or detractors) allow for formatting items. `vertical: true` can also be provided to change the orientation. The default is horizontal spread.

    ```typst
    #let formatted_text = [There was a *bold* thing.]
    ```
    #let formatted_text = [*bold* thing.]

    #MultipleChoice(formatted_text, ("D", "E", "G", 56), vertical: true)
  ]
