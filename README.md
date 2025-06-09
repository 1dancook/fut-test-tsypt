# fut-test-tsypt
Typst template and functions for creating dynamic (randomly) organized tests.


## Project Goals
- test creation with randomization of question order and question options (i.e. in multiple choice questions)
- easy test or worksheet creation with template(s)
- straightforward API with multiple use cases (especially in combination with Typst layout)
- test creation in plain text
- the ability to have a question (and solution/detractor) pool that is drawn from in compilation
- the ability to display answers on an answer key
- automatic generation of question numbering


## Installation

Run `make install` to install on macos. Other OS not implemented but all files can be copied to the appropriate local installation.

## Usage

### In a .typ document
Import with: `#import "@local/fut-test:x.x.x": *` where x.x.x is the version number.

Apply the template:

```typst
#import "@local/fut-test:0.1.4": * // use current version

#show: futtest.with(
  title: "The Test Title",
  supplement: "Units 1-99",
)

// Other test content
// Use Level 2 and Level 3 headers
```



### Compile

By default, if compiled with `typst compile <filename>` the seed for randomization will be based on the time of year and automatically determine the year and term. The seed can be manually provided in the command line invocation and must be an integer, i.e.:

`typst compile --input seed=202501 <filename>`


### Examples (API)

One of the main use cases is with multiple choice questions. Question order and option order is randomized:

```typst
#QuestionSet(
  Question[Some multiple choice question text
  // some options, randomize them
  #MultipleChoice("Option A", ("Option B", "Option C"))
]
)
```


## TODO:

- [x] function for shuffling questions --> `#QuestionSet((array of items))`
- [x] function for options and shuffling options --> `#Question[]`
- [x] convenience function for just having a --> `#Q`
- [x] convenience function for blanks --> `#blank()`
- [x] formatting: box wrap with stroke --> `#boxwrap()`
- [x] convenience function for multiple choice (one or multiple possible solutions, several possible detractors). All shuffled and displayed as options --> `MultipleChoice`
- [x] for `blank`, add the ability to provide a solution that will be highlighted
- [x] options: add a limit to QuestionSet (i.e. so there could be many questions but they are limited)
- [x] cli/compiling: default seed as year/term determined by creation date
- [ ] formatting: box wrap with fill
- [x] marking answers / highlighting --> use sys.input to indicate what type of test
  - [ ] `answerkey=true`
  - [ ] test = (default)
  - [ ] answer sheet = `answers`
  - [ ] study notes = `notes`
- [ ] something based on `Question` but an array of similar questions in which only one is used when compiled (if the similar questions were used in a `QuestionSet` there is potential for a basic duplicate)
  - note: this is probably not going to work because of the nesting of randomness issue
- [x] convenience function for #True (true/false) --> `#True`
- [x] convenience function for #False (true/false) -- `#False`
- [x] convenience function for making matching lists (i.e. key value pairs that get shuffled).
  - --> `#Match`
- [x] convenience function for shuffling words/phrases in a sentence. I.e. input=`this | is | the | input` will be split on `|` and shuffled, displayed with `/` separated values. Answer sheet will show the original. --> `Unscramble`
- [x] Convenience function for cloze passages. I.e. mark the targets with `{}` and the targets will be put in a list. Optional extra words for detractors.
  - --> `#Cloze`
- [ ] convenience function for question and lines (i.e. writing space)
- [ ] cloze with an option to circle (i.e. "(I am / I is) a nice guy.")
- [ ] a 'check' options (multiple choice, but a checkbox is displayed) ... use case: "check all that apply" or "check all that are true"
- [x] a change to multiple choice so that when there is only one solution a box is presented to fill it in (and make it small)
- [ ] add parameter to Option to use checkboxes (instead of numbering)
- [ ] add a 'checkbox' function so that boxes can be used anywhere (i.e. in instructions)
- [ ] ability to use any kind of string as a seed (requires some conversion)


### Todo for repo

- port and make examples of different parts of the package
  - [ ] MultipleChoice
  - [ ] utilities (blank, etc)
  - [ ] Question / QuestionSet
  - [ ] True/False
  - [ ] Unscramble
  - [ ] Match
  - [ ] Cloze

