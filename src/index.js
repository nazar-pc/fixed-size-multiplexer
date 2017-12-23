// Generated by LiveScript 1.5.0
/**
 * @package   Fixed size multiplexer
 * @author    Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @copyright Copyright (c) 2017, Nazar Mokrynskyi
 * @license   MIT License, see license.txt
 */
(function(){
  var to_export;
  to_export = {
    'Multiplexer': Multiplexer,
    'Demultiplexer': Demultiplexer
  };
  if (typeof define === 'function' && define.amd) {
    define(function(){
      return to_export;
    });
  } else if (typeof exports === 'object') {
    module.exports = to_export;
  } else {
    this['fixed_size_multiplexer'] = to_export;
  }
  /**
   * @param {!Uint8Array} array
   *
   * @return {number}
   */
  function uint_array_to_number(array){
    var number, multiply, i$, byte;
    number = 0;
    multiply = 1;
    for (i$ = array.length - 1; i$ >= 0; --i$) {
      byte = array[i$];
      number += byte * multiply;
      multiply *= Math.pow(2, 8);
    }
    return number;
  }
  /**
   * @param {number} number
   *
   * @return {!Uint8Array}
   */
  function number_to_uint_array(number, length){
    var array, i$, offset, byte;
    array = new Uint8Array(length);
    for (i$ = length - 1; i$ >= 0; --i$) {
      offset = i$;
      byte = number % Math.pow(2, 8);
      number = (number - byte) / Math.pow(2, 8);
      array.set([byte], offset);
    }
    return array;
  }
  /**
   * @param {!Object}	object
   * @param {number}	max_data_length
   * @param {number}	block_size
   */
  function initialize(object, max_data_length, block_size){
    object._max_data_length = max_data_length;
    object._block_size = block_size;
    object._block_size_header_bytes = 1;
    while (max_data_length >= Math.pow(2, 8)) {
      ++object._block_size_header_bytes;
      max_data_length /= Math.pow(2, 8);
    }
    object._buffer = new Uint8Array(0);
  }
  /**
   * Multiplexes data chunks into blocks of fixed size
   *
   * @constructor
   *
   * @param {number} max_data_length	Max size of data in bytes (influences data header size)
   * @param {number} block_size		Size of one block of data
   */
  function Multiplexer(max_data_length, block_size){
    if (!(this instanceof Multiplexer)) {
      return new Multiplexer(max_data_length, block_size);
    }
    initialize(this, max_data_length, block_size);
  }
  Multiplexer.prototype = {
    /**
     * @param {!Uint8Array} data
     */
    'feed': function(data){
      var x$, new_buffer;
      x$ = new_buffer = new Uint8Array(this._buffer.length + this._block_size_header_bytes + data.length);
      x$.set(this._buffer);
      x$.set(number_to_uint_array(data.length, this._block_size_header_bytes), this._buffer.length);
      x$.set(data, this._block_size_header_bytes + this._buffer.length);
      this._buffer = new_buffer;
    }
    /**
     * @return {boolean}
     */,
    'have_more_blocks': function(){
      return this._buffer.length > 0;
    }
    /**
     * @return {!Uint8Array}
     */,
    'get_block': function(){
      var block, to_read;
      block = new Uint8Array(this._block_size);
      if (this.have_more_blocks()) {
        to_read = Math.min(this._block_size, this._buffer.length);
        block.set(this._buffer.subarray(0, to_read));
        this._buffer = this._buffer.subarray(to_read);
      }
      return block;
    }
  };
  Object.defineProperty(Multiplexer.prototype, 'constructor', {
    enumerable: false,
    value: Multiplexer
  });
  /**
   * Demultiplexes data chunks from blocks of fixed size
   *
   * @constructor
   *
   * @param {number} max_data_length	Max size of data in bytes (influences data header size)
   * @param {number} block_size		Size of one block of data
   */
  function Demultiplexer(max_data_length, block_size){
    if (!(this instanceof Demultiplexer)) {
      return new Demultiplexer(max_data_length, block_size);
    }
    initialize(this, max_data_length, block_size);
    this._pending_blocks = [];
  }
  Demultiplexer.prototype = {
    /**
     * @param {!Uint8Array} block
     */
    'feed': function(block){
      if (this.have_more_data()) {
        this._pending_blocks.push(block);
      } else {
        this._feed(block);
      }
    }
    /**
     * @param {!Uint8Array} block
     */,
    _feed: function(block){
      var x$, new_buffer;
      x$ = new_buffer = new Uint8Array(this._buffer.length + block.length);
      x$.set(this._buffer);
      x$.set(block, this._buffer.length);
      this._buffer = new_buffer;
    }
    /**
     * @return {boolean}
     */,
    'have_more_data': function(){
      this._fill_buffer();
      return this._have_more_data();
    }
    /**
     * @return {boolean}
     */,
    _have_more_data: function(){
      var data_length;
      if (this._buffer.length <= this._block_size_header_bytes) {
        return false;
      }
      data_length = uint_array_to_number(this._buffer.subarray(0, this._block_size_header_bytes));
      if (!data_length) {
        this._buffer = new Uint8Array(0);
      }
      return data_length !== 0 && this._buffer.length >= this._block_size_header_bytes + data_length;
    }
    /**
     * @return {Uint8Array}
     */,
    'get_data': function(){
      var data_length, data;
      if (!this.have_more_data()) {
        return null;
      }
      data_length = uint_array_to_number(this._buffer.subarray(0, this._block_size_header_bytes));
      data = this._buffer.subarray(this._block_size_header_bytes, this._block_size_header_bytes + data_length);
      this._buffer = this._buffer.subarray(this._block_size_header_bytes + data_length);
      return data;
    },
    _fill_buffer: function(){
      var data_length;
      for (;;) {
        if (this._have_more_data() || !this._pending_blocks.length) {
          break;
        }
        data_length = uint_array_to_number(this._buffer.subarray(0, this._block_size_header_bytes));
        if (!data_length) {
          this._buffer = new Uint8Array(0);
        }
        this._feed(this._pending_blocks.shift());
      }
    }
  };
  Object.defineProperty(Demultiplexer.prototype, 'constructor', {
    enumerable: false,
    value: Demultiplexer
  });
}).call(this);
