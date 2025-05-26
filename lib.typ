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
#let rng = state("rng", (gen-rng(seed), none))

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

#let round_numbering(num) = {
  box(
    baseline: 1.5pt,
    circle(radius: 5pt, fill: none, stroke: 1pt + black, inset: 0pt)[
      #set align(center + horizon)
      #text(size: 8pt, num)
    ],
  )
}

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
      round_numbering(numbering(style, i + 1))
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



#let QuestionSet(q_set, limit: none, randomize: true) = {
  if limit == none {
    // FIX: handle other values (negative int, etc)
    limit = q_set.len()
  } else {
    randomize = true // limit will be applied by random choice so randomization must be on
  }

  /* NOTE: there is a severe limitation from typst resulting in nested randomization being not possible and/or extremely fragile. Currently doing true randomization here that requires context will result in an error (show rule depth exceeded). Thus, currently this is a hack workaround - because using the other randomization method (that relies on context), the nested context will result in a convergence issue and the document will not compile. this work around uses a local_rng based on the same seed. some issues with this could be similar order across question sets (especially when the number of question items is similar), however, since this has to do with question order it may not be quite noticeable, and it is still a shuffle regardless.
   */
  let randomize_question_set(q_set, limit) = {
    let local_rng = gen-rng(seed)
    let (_, shuffled) = choice(local_rng, q_set, size: limit, replacement: false)
    shuffled.join()
  }

  if randomize {
    //randomize_question_set(q_set, shuffled => shuffled.join())
    randomize_question_set(q_set, limit)
  } else {
    q_set.join()
  }
}



#let MultipleChoice(
  solution_items,
  detractor_items,
  solutions: none,
  detractors: none,
  left_pad: 0em,
  vertical: false,
  columns: none,
) = {
  let combined_shuffle(solution_items, detractor_items, solutions, detractors, callback) = {
    // first, do random choice and store A
    rng.update(((rng, _)) => choice(rng, solution_items, size: solutions, replacement: false))
    // second, do choice from B and store A+B
    rng.update(((rng, shuffled_solutions)) => {
      let (new_rng, shuffled_detractors) = choice(rng, detractor_items, size: detractors, replacement: false)
      (new_rng, shuffled_solutions + shuffled_detractors)
    })
    // third, do shuffle of A+B (combined options)
    rng.update(((rng, combined_options)) => shuffle(rng, combined_options))

    context callback(rng.get().last())
  }


  // The case when a single solution is provided.
  // convert it to an array for later
  if type(solution_items) != array {
    solution_items = (solution_items,)
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
  solution_items = solution_items.map(it => if hl { hl_solution(it) } else { it })

  if solutions == none { solutions = solution_items.len() }
  if detractors == none { detractors = detractor_items.len() }

  // set the number of columns to use
  columns = if vertical { 1 } else if columns != none { columns } else { solutions + detractors }
  // send to nested function to shuffle, display the results from the callback
  combined_shuffle(
    solution_items,
    detractor_items,
    solutions,
    detractors,
    shuffled => [
      #options(shuffled, columns: columns, expand: true, left_pad: left_pad)
    ],
  )
}





#let Order(number, target_text) = {
  box(baseline: 0.3em)[#grid(
      columns: (auto, auto),
      column-gutter: 1.5em,
      [
        #if hl {
          box(
            height: 1.2em,
            width: 1.2em,
            fill: red.lighten(70%),
            stroke: 1pt,
            baseline: 0.25em,
            [#set align(center + horizon); #number],
          )
        } else {
          box(height: 1.2em, width: 1.2em, stroke: 1pt, baseline: 0.25em)
        }],
      [#target_text],
    )]
}


#let True = options((hl_solution("True"), "False"), left_pad: 3em)
#let False = options(("True", hl_solution("False")), left_pad: 3em)



#let Match(pairs, detractors: none, style: "A", col_size: (1fr, 1fr)) = {
  let process_string(it) = {
    // a function to process the key/value strings
    // substitution of #blank for a blank line
    // any typst markup will work
    let blank_line = box(width: 2.5em, height: 1em, stroke: (bottom: 1pt))
    return eval(it, mode: "markup", scope: (blank: blank_line))
  }

  // first, give the left side and right side an identical index and make two arrays
  let (left_side, right_side) = (
    pairs.keys().enumerate().map(((i, item)) => (i, process_string(item))),
    pairs.values().enumerate().map(((i, item)) => (i, process_string(item))),
  )


  // Next, add any detractors on the right side
  // the index and value will be the same here as the index doesn't matter
  // for detractors
  if detractors != none {
    if type(detractors) == str {
      right_side.push((detractors, detractors))
    } else if type(detractors) == array {
      for item in detractors {
        right_side.push((item, item))
      }
    }
  }


  // Next, send the left and right side to be randomized and continue from there
  let randomize_left_right(left, right, callback) = {
    // returns an array of (left, right)
    rng.update(((rng, _)) => shuffle(rng, left))
    rng.update(((rng, shuffled_left)) => {
      let (newrng, shuffled_right) = shuffle(rng, right)
      (rng, (shuffled_left, shuffled_right))
    })
    context callback(rng.get().last())
  }


  randomize_left_right(
    left_side,
    right_side,
    shuffled => {
      let (left_side, right_side) = shuffled

      // The following adds a typst numbering type to the left and right side items
      // depending on their order (after being randomized)
      // This numbering is then used in compilation for both sides, but for the left side
      // when answer highlighting is turned on

      // add numbering to the right side first
      let numbered_right = right_side.enumerate().map(((i, (index, item))) => (index, item, numbering(style, i + 1)))

      // iterate over left side, matching with right side (based on index)
      // create a new array for the left that contains numbering
      let numbered_left = ()
      for (index_left, key) in left_side {
        for (index_right, value, num) in numbered_right {
          if index_left == index_right {
            numbered_left.push((index_left, key, num))
          }
        }
      }

      // finally, display

      grid(
        columns: col_size,
        column-gutter: 4em,
        align: horizon,

        [
          #for (index, key, num) in numbered_left [
            #Question[ #Order(num, key) ] // #Order has the layout that I would like
          ]
        ],
        boxwrap([
          #for (index, value, num) in numbered_right [
            #round_numbering(num) #h(4pt) #value #linebreak()
          ]
        ]),
      )
    },
  )
}




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
