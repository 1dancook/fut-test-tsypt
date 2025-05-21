# fut-test-tsypt
Typst template and functions for creating dynamic (randomly) organized tests.


## Installation

Run `install_macos.sh` to install the package to use as a local package and template.

## Usage

### In a .typ document
Import with: `#import "@fut/fut-test:x.x.x": *` where x.x.x is the version number.

Apply the template:

```typst
#import "@fut/fut-test:0.0.1": * // use current version

#show: futtest.with(
  course: "the course name",
  test_number: "1",
  test_coverage: "units 1-99",
)

// Other test content
// Use Level 2 and Level 3 headers
```



### Compile

By default, if compiled with `typst compile <filename>` the seed for randomization will be based on the time of year and automatically determine the year and term. The seed can be manually provided in the command line invocation and must be an integer, i.e.:

`typst compile --input seed=202501 <filename>`


### Examples (API)

One of the main use cases is with multiple choice questions. Question order and option order is randomized. By default, `#options` is not randomized.

```typst
#QuestionSet((
Question[Some multiple choice question text
// some options, randomize them
#options(("Option A", "Option B", "Option C"), randomize: true)
]
))
```


## TODO:

- [x] function for shuffling questions --> `#QuestionSet((array of items))`
- [x] function for options and shuffling options --> `#Question[]`
- [x] convenience function for just having a --> `#Q`
- [x] convenience function for blanks --> `#blank()`
- [x] formatting: box wrap with stroke --> `#boxwrap()`
- [ ] options: add a limit to QuestionSet (i.e. so there could be many questions but they are limited)
- [ ] cli/compiling: default seed as year/term determined by creation date
- [ ] formatting: box wrap with fill
- [ ] marking answers / highlighting --> use sys.input to indicate what type of test
  - [ ] test = (default)
  - [ ] answer sheet = `answers`
  - [ ] study notes = `notes`
- [ ] something based on `Question` but an array of similar questions in which only one is used when compiled (if the similar questions were used in a `QuestionSet` there is potential for a basic duplicate)
- [ ] convenience function for #True (true/false)
- [ ] convenience function for #False (true/false)
- [ ] convenience function for multiple choice (one answer, several wrong answers). The first answer will be the correct one, marked as such, and all of them shuffled
- [ ] convenience function for making matching lists (i.e. key value pairs that get shuffled). Currently I'm not sure how the answers would work out for this but there is a way.
- [ ] convenience function for shuffling words/phrases in a sentence. I.e. input=`this | is | the | input` will be split on `|` and shuffled, displayed with `/` separated values. Answer sheet will show the original.
- [ ] Convenience function for cloze passages. I.e. mark the targets with `{}` and the targets will be put in a list. Optional extra words for detractors.
  - related: single sentence cloze with multiple options separated by a `|` i.e. `{one|two|three}`
- [ ] convenience function for question and lines (i.e. writing space)
