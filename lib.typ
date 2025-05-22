#import "@preview/suiji:0.4.0": *

// SET UP FOR SEED AND RANDOMIZATION
// This will rely on system inputs
// This has to do with difficulty getting the rng working in context (and taking seed from template input)
// It seems as though using `context` would fix this, but it doesn't work.
// A minimal example to reproduce and work around the issue might be better, but at the moment the sys.inputs allows for scripting the generation of tests based on year and term and this is sufficient
//
// The default values here are to use the current year and term
// Any custom/manual seed should be done in the command line
#let _year = datetime.today().year()
#let _month = datetime.today().month()
#let _term = if _month >= 4 and _month <= 8 { 1 } else { 2 }
#let _default_seed = str(_year) + "0" + str(_term) // string
#let seed = int(sys.inputs.at("seed", default: _default_seed))
#let rng = gen-rng-f(seed)


// SET UP FOR THE QUESTION COUNTER
#let question_counter = counter("question_counter")

// Set up for highlighting solutions
// TODO: change this to be a parameter set in the command line input
// i.e. --input solutions:true
#let hl = false

#let hl_solution(solution) = if hl {
  box(stroke: 2pt + red.lighten(40%), outset: 0.3em, fill: red.lighten(70%), solution)
} else {
  solution
}



// FOLLOWING ARE FUNCTIONS

#let boxwrap(contents) = [
  #box(stroke: 1pt + rgb("#777"), radius: 3pt, inset: 1em)[
    #contents
  ]
]

// TODO: make a filled box


#let _qnum_box(qnum) = box(
  width: 1.5em,
  baseline: 0.25em,
  box(fill: rgb("#666"), height: 1.2em, radius: 2pt, outset: (x: 3pt), baseline: 0.25em)[
    #set align(center + horizon)
    #text(
      fill: white,
      weight: "bold",
    )[#qnum]],
)

#let Q = context {
  question_counter.step()
  h(0.5em)
  _qnum_box(question_counter.display())
  h(0.5em)
}


#let Question(question_content, breakable: false, below: 0.8em) = context {
  question_counter.step()
  let numberbox = _qnum_box(question_counter.display())
  set par(hanging-indent: measure(numberbox).width + 1em + 3pt)
  block(
    breakable: breakable,
    below: below,
    [
      #h(0.5em) #numberbox #h(0.5em) #question_content
    ],
  )
}

// ------------------------------

#let blank(..args) = [
  #let arguments = args.named()
  #if "width" not in args.named().keys() {
    arguments.width = 40pt
  }
  #if args.pos().len() > 0 {
    arguments.width = args.pos().first()
  }
  #box(stroke: (bottom: 1pt + black), ..arguments)
]



#let options(
  items,
  columns: 3,
  style: "A",
  randomize: false,
  left_pad: 0em,
  right_pad: 0em,
  expand: false,
  above: 0.5em,
  below: 0.5em,
) = {
  // shuffle the items if required
  if randomize {
    (_, items) = shuffle(rng, items)
  }


  // Enumerate items with lettering and encapsulate the lettering with a circle
  let numbered = items
    .enumerate()
    .map(((i, item)) => {
      box(
        baseline: 1.5pt,
        circle(radius: 5pt, fill: none, stroke: 1pt + black, inset: 0pt)[
          #set align(center + horizon)
          #text(size: 8pt, numbering(style, i + 1))
        ],
      )
      h(4pt)
      item
    })

  // deal with columns - create an array that is filled with 1fr based on the number of columns
  if expand {
    columns = (1fr,) * columns
  }


  // Create grid with specified number of columns
  block(
    inset: (left: left_pad, right: right_pad),
    above: above,
    below: below,
    grid(
      columns: columns,
      column-gutter: 2.5em,
      row-gutter: 0.8em,
      ..numbered
    ),
  )
}



#let QuestionSet(q_set, randomize: true) = {
  if randomize {
    (_, q_set) = shuffle(rng, q_set)
  }
  q_set.join()
}

#let MultipleChoice(
  solution_items,
  detractor_items,
  solutions: none,
  detractors: none,
  left_pad: 0em,
  vertical: false,
) = {
  // Multiple Choice options require solutions and detractors.
  // Solutions can be provided as a single item not in an array
  // A single item is the most likely use case
  // Multiple solutions can be provided, and a limit set on how many are used.
  // In this way this function can be used to construct many types of multiple choice: single solution, or multiple solution option sets.
  // Detractor items must be in an array.

  // The case when a single solution is provided.
  // convert it to an array for later
  if type(solution_items) != array {
    solution_items = (solution_items,)
  } else if type(solution_items) == array {
    // there could be one or more solution_items, provided in an array
    // use all the solutions if no limit is specified (none)
    if solutions == none { solutions = solution_items.len() }

    // the limit will be applied and solutions randomly chosen
    if solution_items.len() > 1 and solutions <= solution_items.len() {
      // replacement is necessary here to prevent duplicates
      (_, solution_items) = choice(rng, solution_items, size: solutions, replacement: false)
    }
  }

  // handle any solution items being an integer -- convert to string
  for (index, item) in solution_items.enumerate() {
    if type(item) == int {
      solution_items.at(index) = str(solution_items.at(index))
    }
  }


  // handle any detractor items being an integer -- convert to string
  for (index, item) in detractor_items.enumerate() {
    if type(item) == int {
      detractor_items.at(index) = str(detractor_items.at(index))
    }
  }

  // highlight all solution_items
  let solution_items = solution_items.map(it => if hl { hl_solution(it) } else { it })


  // It is assumed that the provided detractor_items are all needed
  // unless a limit is set with `detractors`
  if detractors != none and detractors >= 1 and detractors <= detractor_items.len() {
    // randomly choose detractor_items to use
    // replacement is necessary here to prevent duplicates
    (_, detractor_items) = choice(rng, detractor_items, size: detractors, replacement: false)
  }

  let option_items = solution_items + detractor_items

  // render as option items
  let columns = if vertical { 1 } else { option_items.len() }
  options(option_items, columns: columns, expand: true, left_pad: left_pad, randomize: true)
}



#let Order(number, target_text) = [
  #h(1em)
  #if hl [
    #box(
      height: 1.2em,
      width: 1.2em,
      fill: red.lighten(70%),
      stroke: 1pt,
      baseline: 0.25em,
      [#set align(center + horizon); #number],
    )
  ] else [
    #box(height: 1.2em, width: 1.2em, stroke: 1pt, baseline: 0.25em)
  ]
  #h(1em)
  #target_text
]


#let True = options((hl_solution("True"), "False"), left_pad: 2.5em)
#let False = options(("True", hl_solution("False")), left_pad: 2.5em)




// FOLLOWING IS FOR THE PAGE TEMPLATE



#let futtest(
  course: "Course Name",
  test_number: "1",
  test_coverage: "Units 1-99",
  body,
) = {
  // PAGE SETUP
  set text(
    font: ("Helvetica", "Noto Sans Mono CJK JP", "Helvetica Neue"),
    weight: "regular",
    size: 10pt,
  )


  set page(
    paper: "a4",
    margin: (x: 1.6cm, y: 1.5cm),
    // show the page number and the seed number
    footer: context [#h(1fr) #counter(page).display("1/1", both: true) #h(1em) #seed #h(1fr)],
  )

  set par(
    justify: true,
    leading: 0.8em,
  )

  // -----------------------

  show heading.where(level: 2): element => box(
    stroke: (left: 5pt + rgb("#888")),
    outset: 0pt,
    fill: rgb("#eee"),
    width: 1fr,
    inset: 10pt,
  )[#element]

  show heading.where(level: 1): element => align(center)[#v(0.5em) #element #v(0.5em)]

  let numbox = box(stroke: 1pt, height: 1.3em, width: 1.3em)

  let student_number_box = box(
    grid(
      columns: 8,
      gutter: 0pt,
      numbox, numbox, numbox, numbox, numbox, numbox, numbox, numbox,
    ),
    baseline: 0.3em,
  )

  grid(
    columns: (0.7fr, 1.3fr),
    gutter: 1em,
    box(baseline: 0em, [学績番号: #student_number_box]), box(baseline: 1em, [氏名: #blank(1fr)]),
  )

  [= #course #h(3em) Test #test_number #h(3em) (#test_coverage) ]

  // The question counter should be initially stepped here
  question_counter.step()

  // Include the body of the test from the user document
  body
}
