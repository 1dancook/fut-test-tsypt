#let invertedgrid(
  ..args,
) = {
  // the default columns for grid seems to be 1
  // we need to explicitly have the columns for the algorithm
  let columns = {
    let c = args.named().at("columns", default: 1)
    if c == auto { 1 } else { c }
  }

  // get all the children in an array to use for reassembly
  let arr = args.pos()

  let reassemble_arr(arr, columns) = {
    /*
    this algorithm works by first calculating the
    empty cells that would be in the grid
    a few other variables are set in order to deal with
    logic for decomposing and recomposing the array

    A normal grid would lay out an array as follows
    0 1 2
    3 4 5
    6 x x

    This algorithm will disassemble an array and reassemble it
    so that the resulting grid will be, for example:
    0 3 5
    1 4 6
    2 x x

    Note that the number of columns are respected
    */

    let remaining = calc.rem(arr.len(), columns)
    let empty_cells = columns - remaining
    if empty_cells == columns { empty_cells = 0 }


    let row_count = int((arr.len() + empty_cells) / columns) // use for chunking and for recompiling the arrays later


    // slice the array into chunks (equal to the number of arrays)
    let chunks = ()
    let start_pos = 0 // start position for the slice
    let chunk_length = row_count // the chunk_length will initially need to be the same as how many rows we will use
    for col in range(columns) {
      /*
       this is to deal with filling the last row with empty cells
       - the empty cells will be on last row, bottom right
       - the logic is using the 'remaining' value as an indicator
         of columns in which to apply the chunk length modification
       - it should not apply before remaining
       - not when there are no remaining cells
       - and not on the last column
      */
      if col == remaining and remaining != 0 and (col + 1) < columns {
        chunk_length -= 1
      }

      // chunk and push
      let slice = arr.slice(start_pos, count: chunk_length)
      chunks.push(slice)

      // set the start position for the next chunk
      start_pos = start_pos + chunk_length

      // make sure the next chunk doesn't extend past the array length
      if start_pos + chunk_length > arr.len() {
        chunk_length = arr.len() - start_pos
      }
    }

    // reassemble the cells based by the chunks and index
    // empty cells will be grid.cell(none)
    let reassembled = ()
    for i in range(row_count) {
      for chunk in chunks {
        // the i-th element of each chunk will be pushed
        reassembled.push(chunk.at(i, default: grid.cell(none)))
      }
    }

    reassembled
  }

  // the flipping algorithm should only be applied when there is more than one column
  if columns > 1 {
    arr = reassemble_arr(arr, columns)
  }

  // display in a grid, forwarding other args and then the array
  grid(
    ..args.named(),
    ..arr
  )
}
