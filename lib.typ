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

// SET UP FOR THE HEADING COUNTER
#let section_number = counter("section_number")

// Some other stylistic globals
#let question_fill_color = black
#let dark_color = black
#let light_gray = gray.lighten(50%)
#let faint_gray = gray.lighten(60%)
#let box_inset = 0.8em

// Set up for highlighting solutions
#let answerkey = {
  // i.e. --input answerkey:true
  // have to deal with strings, and bool does not have a constructor
  let ak = sys.inputs.at("answerkey", default: false)
  if type(ak) == str and ak in ("true", "false") {
    ak = eval(ak)
  }
  ak
}

#let hl_solution(solution) = if answerkey {
  box(stroke: 2pt + red, outset: 0.3em, fill: red.lighten(70%), solution)
} else {
  solution
}



// FOLLOWING ARE FUNCTIONS


#let SectionHeading(title, instructions: none) = layout(size => {
  section_number.step()
  let num = context { section_number.display() }

  // Define column widths
  let numbox_width = measure(text(white, 2.5em, weight: "bold")[#num]).width + 16pt
  let col1 = numbox_width
  let col2 = (size.width - col1)

  let instruction_text = instructions
  let title = text(1.3em, weight: "bold", title)
  let instructions = text(instructions)
  let num = text(white, 2.5em, weight: "bold", num)

  // Measure the height of the title and subtitle to align the triangle
  let min-height = 32pt
  let vertical-padding = 14pt
  let title-box = measure(width: col2, title).height + (vertical-padding)
  let instructions-box = measure(width: col2, instructions).height + (vertical-padding)
  let number-box = measure(width: col1, num).height + (vertical-padding)
  let title_instruction = title-box + instructions-box
  if instruction_text == none {
    title_instruction = title-box
  }
  let content-height = calc.max(title_instruction, number-box, min-height)

  // Assemble the grid
  grid(
    columns: (col1, col2), align: left + horizon, gutter: 0pt, column-gutter: 0pt,

    // Column 1: Numbering
    box(
      fill: dark_color,
      width: col1,
      height: content-height,
      stroke: 1pt,
      inset: (y: vertical-padding),
      align(center, num),
    ),
    // Column 2: Triangle
    //box(fill: light_gray, clip: true, stroke: (left: 2pt + dark_color), triangle),
    // Column 3: Title and Subtitle
    box(
      fill: light_gray,
      width: col2,
      height: content-height,
      stroke: 1pt,
      inset: (y: vertical-padding, x: 8pt),
      [
        #title \ #instructions
      ],
    )
  )
})



#let boxwrap(contents) = [
  #box(stroke: 1pt + dark_color, radius: 3pt, inset: 1em)[
    #contents
  ]
]

// TODO: make a filled box


#let _qnum_box(qnum) = box(
  width: 1.5em,
  box(fill: question_fill_color, height: 1.2em, radius: 2pt, inset: (x: 3pt))[
    #set align(center + horizon)
    #text(
      fill: white,
      weight: "bold",
    )[#qnum]],
)

#let Q = context {
  question_counter.step()
  _qnum_box(question_counter.display())
}

#let QuestionNum = context {
  question_counter.step()
  question_counter.display()
}


#let Question(question_content, breakable: false, below: 0.8em) = context {
  question_counter.step()
  let numberbox = _qnum_box(question_counter.display())
  block(
    breakable: breakable,
    below: below,
    grid(
      columns: 2,
      column-gutter: 0.5em,
      align: top,
      [#h(0.5em) #numberbox], box(inset: (top: 2pt), question_content),
    ),
  )
}

// ------------------------------

#let blank(..args) = {
  // some of the defaults for blank will be determined by whether an answer should be displayed
  let answer_mode = if args.pos().len() > 0 and answerkey { true } else { false }

  // whatever is provided in positional args will be converted to content
  let body = []
  if answer_mode {
    body = align(horizon, text(fill: red, [#args.pos().at(0)]))
  }


  let passed_args = (
    width: args.named().at("width", default: if answer_mode { auto } else { 40pt }),
    stroke: args.named().at("stroke", default: (if not answer_mode { (bottom: 1pt + black) })),
    inset: args.named().at("inset", default: 3pt),
    height: args.named().at("height", default: 1em),
    baseline: args.named().at("baseline", default: 1pt),
    outset: (y: 1pt),
    fill: if answer_mode { (red.transparentize(80%)) },
  )

  box(..passed_args, body)
}


#let round_numbering(num) = {
  box(
    baseline: 1.5pt,
    circle(radius: 5pt, fill: dark_color, stroke: 1pt + dark_color, inset: 0pt)[
      #set align(center + horizon)
      #text(size: 8pt, fill: white, num)
    ],
  )
}

#let options(
  items,
  columns: 3,
  style: "A",
  left_pad: 0em,
  right_pad: 0em,
  expand: false,
  above: 0.5em,
  below: 0.5em,
) = {
  // FIX: this function should take some randomization but it may be better to use this as a backend function
  // and introduce an API in a different function

  // Enumerate items with lettering and encapsulate the lettering with a circle
  let numbered = items
    .enumerate()
    .map(((i, item)) => {
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



#let QuestionSet(
  heading: none,
  limit: none,
  randomize: true,
  rows: auto,
  columns: auto,
  column-gutter: 1em,
  row-gutter: 1.2em,
  column-rule: false,
  breakable: false,
  ..questions,
) = {
  // get all the positional argument as questions
  // everything is is a named argument
  let q_set = questions.pos()

  if limit == none {
    // FIX: handle other values (negative int, etc)
    limit = q_set.len()
  } else {
    randomize = true // limit will be applied by random choice so randomization must be on
  }

  columns = if columns == auto { 1 } // use a default value of 1

  let GridLayout(qs) = {
    let args = arguments(rows: rows, columns: columns, column-gutter: column-gutter, row-gutter: row-gutter)
    // if there is a header it will be inserted as the first grid cell
    // with a span for the entire grid.
    if heading != none {
      qs = (grid.cell(colspan: columns, [=== #heading]),) + qs
    }
    // insert column-rule (vertical lines)
    if column-rule and type(columns) == int {
      for col in range(1, columns) {
        // offset the start of the vline if there is a heading
        let start = if heading != none { 1 } else { 0 }
        qs.push(grid.vline(x: col, start: start, stroke: 1pt))
      }
    }
    // the grid is wrapped in a block to take advantage of breakable
    block(
      breakable: breakable,
      grid(
        ..args,
        ..qs
      ),
    )
  }

  /* NOTE: there is a severe limitation from typst resulting in nested randomization being not possible and/or extremely fragile. Currently doing true randomization here that requires context will result in an error (show rule depth exceeded). Thus, currently this is a hack workaround - because using the other randomization method (that relies on context), the nested context will result in a convergence issue and the document will not compile. this work around uses a local_rng based on the same seed. some issues with this could be similar order across question sets (especially when the number of question items is similar), however, since this has to do with question order it may not be quite noticeable, and it is still a shuffle regardless.
   */
  let randomize_question_set(q_set, limit) = {
    let local_rng = gen-rng(seed)
    let (_, shuffled) = choice(local_rng, q_set, size: limit, replacement: false)
    GridLayout(shuffled)
  }

  if randomize {
    //randomize_question_set(q_set, shuffled => shuffled.join())
    randomize_question_set(q_set, limit)
  } else {
    GridLayout(q_set)
  }
}



#let MultipleChoice(
  solution_items,
  detractor_items,
  solutions: none,
  detractors: none,
  left_pad: 0.5em,
  vertical: false,
  columns: none,
) = {
  // TODO: (maybe) add a small box for answers (only when there is one solution). It can be on the left side or right side, this can be done with a grid
  // FIX: change the api to be consistent -- solutions, detractors, solution_limit, detractor_limit
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
  solution_items = solution_items.map(it => if answerkey { hl_solution(it) } else { it })

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





#let Order(number, target_text, top_offset: -2pt) = {
  box(
    inset: (top: top_offset), // this is here to deal with the offset from Question
    grid(
      columns: (auto, auto),
      column-gutter: 1.3em,
      align: top,
      [
        #h(0.5em) // provide a bit of horizontal space
        #if answerkey {
          box(
            height: 1.2em,
            width: 1.2em,
            fill: red.lighten(70%),
            stroke: 1pt,
            [#set align(center + horizon); #number],
          )
        } else {
          box(height: 1.2em, width: 1.2em, stroke: 1pt)
        }],
      box(inset: (top: 3pt), target_text),
    ),
  )
}


#let True = options((hl_solution("True"), "False"), left_pad: 3em)
#let False = options(("True", hl_solution("False")), left_pad: 3em)



#let Match(pairs, detractors: none, style: "A", col_size: (1fr, 1fr)) = {
  let process_string(it) = {
    // a function to process the key/value strings
    // substitution of #blank for a blank line
    // any typst markup will work
    let blank_line = box(width: 2.5em, stroke: (bottom: 1pt + dark_color))
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

  // TODO: add detractors and detractor_limit which should be processed first for formatting, but then send to the
  // randomize function to be included in the process and should have a random choice applied given the limit


  // TODO: since this creates a number of randomized questions, it should also apply a limit to how many questions are used
  // this should be done in the randomization as a stage and a new function parameter needs to be added
  //
  //
  // TODO: additionally, if the number of dict items is greater than the question limit, it may be possible to use
  // values from the non-randomly-chosen items as detractors. This approach would require more careful construction of
  // items so that a right side value doesn't apply to more than one left side value


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

        box(
          inset: box_inset,
          radius: 3pt,
          stroke: 1pt + light_gray,
          fill: light_gray,
          { for (index, value, num) in numbered_right [ #round_numbering(num) #h(4pt) #value #linebreak() ] },
        ),
      )
    },
  )
}



#let Cloze(
  cloze_content, // a string
  detractor_list: none, // str, int, or array of str/int
  detractors: 1, // int
  show_solutions: "hidden", // default is to not show, or use "top", "left"
  show_question_numbers: false,
  style: "A",
) = {
  // basically the approach here will be to treat the in cloze parts of the text as static, they obviously can't be shuffled. We can, however, shuffle the solutions (if there are many).
  // So this algorithm is designed to first parse and reorganize the given text into chunks of text or solutions. Solutions are given an index number.
  // Following that, solutions are randomized, then given a 'numbering'.
  // The chunks in the main array are then iterated through. When there is a cloze, the index will be matched in the solutions.
  // The cloze item can then hold the same numbering as the solution
  // finally, displayed - and the cloze can show the numbering when highlighting answers is turned on


  // this will not be parameterized as it adds a lot of extra logic
  let cloze_pattern = "\{.*?\}"

  // first, match the cloze pattern
  let solutions = cloze_content.matches(regex(cloze_pattern))

  // convert the cloze content to various chunks of either text or an array (the array will hold other data through the process)
  let chunked = ()
  let last_pos = 0 // last starting index position, should start at 0
  for (i, item) in solutions.enumerate() {
    // it may seem like we need to have some condition for when a solution is at position 0,
    // however, when that occurs the first chunk is an empty string which does not cause an issue

    // get normal text
    chunked.push(cloze_content.slice(last_pos, item.start))

    // get the item text, trim and lower it
    chunked.push((i, lower(item.text.trim("{").trim("}"))))

    // store the end position for next iteration
    last_pos = item.end
  }
  chunked.push(cloze_content.slice(last_pos, cloze_content.len()))


  // extract the indexed_solutions
  let indexed_solutions = chunked.filter(it => type(it) == array)

  // detractors can be either a string, int, or array of strings
  // convert to an array of (type)
  if type(detractor_list) == str {
    detractor_list = (detractor_list,) // convert to array
  } else if type(detractor_list) == int {
    detractor_list = (str(detractor_list),) // convert to array containing string
  } else if detractor_list == none {
    detractor_list = ()
  }
  // make sure all detractors are strings
  detractor_list = detractor_list.map(it => str(it))

  // convert detractor list to an array of (none, detractor) to match the data shape of solutions
  detractor_list = detractor_list.map(it => (none, it))

  // ----------------------------
  // Do randomization and display

  let shuffle_solutions(solutions, detractor_list, detractors, callback) = {
    // first deal with the detractors
    rng.update(((rng, _)) => if detractor_list.len() > 1 {
      choice(rng, detractor_list, size: detractors, replacement: false)
    } else { (rng, detractor_list) })

    // next, combine the detractors and the solutions
    rng.update(((rng, shuffled_detractors)) => {
      let (newrng, shuffled_solutions) = shuffle(rng, solutions + shuffled_detractors)
      (newrng, shuffled_solutions)
    })
    context callback(rng.get().last())
  }


  shuffle_solutions(
    indexed_solutions,
    detractor_list,
    detractors,
    shuffled_solutions => {
      // first add numbering to the shuffled solutions
      let numbered_solutions = shuffled_solutions
        .enumerate()
        .map(((i, (index, item))) => (index, item, numbering(style, i + 1)))

      // next, iterate through the chunked items and add numbering to any array type with a matching index to a numbered solution
      // have to rebuid a new array of chunked items
      let numbered_chunks = ()
      for (x, chunk) in chunked.enumerate() {
        if type(chunk) == array {
          let (index_a, chunk_text) = chunk
          for (index_b, item, num) in numbered_solutions {
            if index_a == index_b {
              numbered_chunks.push((index_a, chunk_text, num))
            }
          }
        } else {
          // any normal string will just be appended as is
          numbered_chunks.push(chunk)
        }
      }


      // pre-format the chunks
      numbered_chunks = numbered_chunks.map(it => {
        // convert these to content items (box)
        let qnum = []
        let solution = []
        if type(it) == array {
          let (index, chunk_text, num) = it
          if show_question_numbers {
            qnum = box(
              fill: question_fill_color,
              inset: 3pt,
              align(center + horizon, text(fill: white, weight: "bold", size: 0.9em, QuestionNum)),
            )
          }
          if answerkey {
            if show_solutions in ("top", "left") {
              // we need the numbering
              solution = align(center + bottom, text(fill: red, num))
            } else {
              solution = align(center + bottom, text(fill: red, chunk_text))
            }
          }
          // set the box width defaults which is different depending on show_solutions
          let box_width = if show_solutions == "hidden" {
            8 * 11pt
          } else { 2.5em } // encourage writing the Letter in the smaller box
          box(
            stroke: (bottom: 1pt + dark_color),
            height: 12pt,
            baseline: 2pt,
            fill: faint_gray,
            radius: (left: 3pt),
            clip: true,
            [#qnum#box(inset: 3pt, baseline: -0pt, width: box_width, solution)],
          )
        } else {
          // just a chunk of text
          it
        }
      })

      // do some formatting of the solutions
      numbered_solutions = numbered_solutions.map(it => {
        let (index, solution, num) = it
        // box to keep it all together
        box([#round_numbering(num) #h(0.3em) #solution])
      })

      let cloze_content_display = align(
        left,
        box(inset: box_inset, radius: 3pt, stroke: 1pt + light_gray, numbered_chunks.join("")),
      )

      let solution_joiner = if show_solutions == "top" { h(2.5em) } else { linebreak() }
      let solutions_display = box(
        inset: box_inset,
        radius: 3pt,
        stroke: 1pt + light_gray,
        fill: light_gray,
        numbered_solutions.join(solution_joiner),
      )

      let columns = 1
      // the default behavior is related to just a single sentence cloze item with no solutions showed.
      let displayed_order = (align(left, numbered_chunks.join("")),)
      if show_solutions == "top" {
        columns = 1
        displayed_order = (solutions_display, cloze_content_display)
      } else if show_solutions == "left" {
        columns = 2
        solutions_display = align(left, solutions_display)
        displayed_order = (cloze_content_display, solutions_display)
      } else if show_solutions == "hidden" and show_question_numbers {
        displayed_order = (cloze_content_display,)
      }

      // wrapping this in a box so that it stays inline (i.e. in combination with #Question)
      grid(
        columns: columns, row-gutter: 0.8em, column-gutter: 0.8em, align: center + top,
        ..displayed_order
      )
    },
  )
}



#let Unscramble(text_input, detractor: none, hint: none, delimiter: "|") = {
  // trim it
  text_input = text_input.trim()

  // extract the last character to use for the writing line (only if it is punctuation)
  let last_char = if text_input.at(-1) in (".", "?") {
    text_input.at(-1)
  } else { "" }
  // then trim it
  text_input = text_input.trim(last_char)

  // remove delimiter and store the solution (making it red text)
  let solution = text(fill: red, weight: "bold", text_input.replace(delimiter, "").replace("  ", " "))

  // lower and trim it
  text_input = lower(text_input)

  // split by delimiter
  let chunks = text_input.split(delimiter).map(it => it.trim())

  // upper any I words
  chunks = chunks.map(it => if it == "i" { "I" } else { it })

  // add the detractor (only if it is string)
  if type(detractor) == str { chunks.push(lower(detractor)) }

  let shuffle_chunks(chunks, callback) = {
    rng.update(((rng, _)) => shuffle(rng, chunks))
    context callback(rng.get().last())
  }

  shuffle_chunks(
    chunks,
    shuffled => {
      let joined_chunks = shuffled.join([#h(0.8em)/#h(0.8em)])

      let full_line = grid(
        columns: (1fr, auto),
        box(height: 12pt, inset: 2pt, stroke: (bottom: 1pt), width: 1fr, if answerkey { solution }),
        box(height: 12pt, inset: 2pt, [#h(0.1em) *#last_char*]),
      )

      let display_order = (joined_chunks, full_line)

      if type(hint) == str {
        display_order = (joined_chunks, text(size: 10pt, [_(Hint: #hint)_]), full_line)
      }


      box(
        //inset: (top: 2pt),
        grid(
          columns: 1, row-gutter: 1em,
          ..display_order,
          v(0.5em)
        ),
      )
    },
  )
}


// FOLLOWING IS FOR THE PAGE TEMPLATE



#let futtest(
  title: "Title of Test",
  subtitle: "subtitle about the test",
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
    margin: (x: 1.2cm, y: 1.5cm),
    // show the page number and the seed number
    footer: context [#h(1fr) #counter(page).display("1/1", both: true) #h(1em) #seed #h(1fr)],
    header: if answerkey [#h(1fr) #box(fill: red, inset: 2pt, text(fill: white, "ANSWER KEY")) #h(1fr) ],
  )

  set par(
    justify: true,
    leading: 0.8em,
  )

  // -----------------------

  show heading.where(level: 2): element => box(
    stroke: (left: 5pt + dark_color),
    outset: 0pt,
    fill: light_gray,
    width: 1fr,
    inset: 10pt,
  )[#element]

  show heading.where(level: 1): element => align(center)[#v(0.5em) #element #v(0.5em)]

  show heading.where(level: 3): element => [#box(width: 5pt, height: 1.5em, fill: dark_color)#box(
      inset: (x: 1em),
      height: 1.5em,
      fill: light_gray,
      align(left + horizon, element),
    )]

  let numbox = box(stroke: 1pt, height: 1.5em, width: 1.5em, baseline: 2pt)

  let student_number_box = box(
    grid(
      columns: 8,
      gutter: 0pt,
      numbox, numbox, numbox, numbox, numbox, numbox, numbox, numbox,
    ),
    baseline: 0.3em,
  )

  grid(
    columns: (1fr, 0.5fr),
    gutter: 1em,
    row-gutter: 0.8em,
    align: horizon,
    text(size: 1.5em, weight: "bold", title), box(baseline: 0em, [学績番号: #h(1fr) #student_number_box]),
    text(size: 1.2em, subtitle), box(baseline: 1em, [氏名: #blank(width: 1fr)]),
    grid.cell(colspan: 2, box(stroke: (bottom: 3pt), height: 1em, width: 1fr))
  )


  // The question counter should be initially stepped here
  question_counter.step()

  // Include the body of the test from the user document
  body
}
