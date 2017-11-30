# Fixed size multiplexer [![Travis CI](https://img.shields.io/travis/nazar-pc/fixed-size-multiplexer/master.svg?label=Travis%20CI)](https://travis-ci.org/nazar-pc/fixed-size-multiplexer)

A tiny library for multiplexing data chunks into blocks of fixed size and vice versa

This library works in Node and in Browser environments (UMD) and is optimized for very small size.

## How to install
```
npm install fixed-size-multiplexer
```

## How to use
Node.js:
```javascript
const {Multiplexer, Demultiplexer} = require('fixed-size-multiplexer')
// Do stuff
```
Browser:
```javascript
requirejs(['fixed-size-multiplexer'], function ({Multiplexer, Demultiplexer}) {
    // Do stuff
})
```

## API

### Multiplexer(max_data_length : number, block_size : number) : Multiplexer
Constructor used to create Multiplexer instance.

* `max_data_length` - Max size of data in bytes (influences data header size)
* `block_size` - Size of one block of data

### Multiplexer.feed(data : Uint8Array)
Feed chunk of data into multiplexer.

### Multiplexer.have_more_blocks() : boolean
Returns true if there are some blocks with useful data left.

### Multiplexer.get_block() : Uint8Array
Get block, potentially with useful data. If no useful data left, will return zeroes (which can be fed into demultiplexer without issues).

### Demultiplexer(max_data_length : number, block_size : number) : Demultiplexer
Constructor used to create Demultiplexer instance.

* `max_data_length` - Max size of data in bytes (influences data header size)
* `block_size` - Size of one block of data

### Demultiplexer.feed(block : Uint8Array)
Feed block, potentially with useful data, into demultiplexer.

### Demultiplexer.have_more_data() : boolean
Returns true if there are complete chunks with useful data present.

### Demultiplexer.get_data() : null|Uint8Array
Get chunk of useful data. If no complete chunk of useful data present yet, returns `null`.


`tests/index.ls` contains usage examples.

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

When reading LiveScript code make sure to configure 1 tab to be 4 spaces (GitHub uses 8 by default), otherwise code might be hard to read.

## License
MIT, see license.txt
