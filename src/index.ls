/**
 * @package   Fixed size multiplexer
 * @author    Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @copyright Copyright (c) 2017, Nazar Mokrynskyi
 * @license   MIT License, see license.txt
 */
to_export	=
	'Multiplexer'	: Multiplexer
	'Demultiplexer'	: Demultiplexer

if typeof define == 'function' && define.amd
	# AMD
	define(-> to_export)
else if typeof exports == 'object'
	# CommonJS
	module.exports = to_export
else
	# Browser globals
	@'fixed_size_multiplexer' = to_export

/**
 * @param {!Uint8Array} array
 *
 * @return {number}
 */
function uint_array_to_number (array)
	number		= 0
	multiply	= 1
	for byte in array by -1
		number		+= byte * multiply
		multiply	*= 2**8
	number

/**
 * @param {number} number
 *
 * @return {!Uint8Array}
 */
function number_to_uint_array (number, length)
	array	= new Uint8Array(length)
	for offset from length - 1 to 0 by -1
		byte	= number % 2**8
		number	= (number - byte) / 2**8
		array.set([byte], offset)
	array

/**
 * @param {!Object}	object
 * @param {number}	max_data_length
 * @param {number}	block_size
 */
!function initialize (object, max_data_length, block_size)
	object._max_data_length			= max_data_length
	object._block_size				= block_size
	object._block_size_header_bytes	= 1
	if max_data_length >= 2**8
		++object._block_size_header_bytes
	if max_data_length >= 2**16
		++object._block_size_header_bytes
	if max_data_length >= 2**32
		++object._block_size_header_bytes
	object._buffer					= new Uint8Array(0)

/**
 * Multiplexes data chunks into blocks of fixed size
 *
 * @constructor
 *
 * @param {number} max_data_length	Max size of data in bytes (influences data header size)
 * @param {number} block_size		Size of one block of data
 */
!function Multiplexer (max_data_length, block_size)
	if !(@ instanceof Multiplexer)
		return new Multiplexer(max_data_length, block_size)

	initialize(@, max_data_length, block_size)

Multiplexer:: =
	/**
	 * @param {!Uint8Array} data
	 */
	'feed' : (data) !->
		new_buffer	= new Uint8Array(@_buffer.length + @_block_size_header_bytes + data.length)
			..set(@_buffer)
			..set(number_to_uint_array(data.length, @_block_size_header_bytes), @_buffer.length)
			..set(data, @_block_size_header_bytes + @_buffer.length)
		@_buffer	= new_buffer
	/**
	 * @return {boolean}
	 */
	'have_more_blocks' : ->
		@_buffer.length > 0
	/**
	 * @return {!Uint8Array}
	 */
	'get_block' : ->
		block	= new Uint8Array(@_block_size)
		if @have_more_blocks()
			to_read		= Math.min(@_block_size, @_buffer.length)
			block.set(@_buffer.subarray(0, to_read))
			@_buffer	= @_buffer.subarray(to_read)
		block

Object.defineProperty(Multiplexer::, 'constructor', {enumerable: false, value: Multiplexer})
/**
 * Demultiplexes data chunks from blocks of fixed size
 *
 * @constructor
 *
 * @param {number} max_data_length	Max size of data in bytes (influences data header size)
 * @param {number} block_size		Size of one block of data
 */
!function Demultiplexer (max_data_length, block_size)
	if !(@ instanceof Demultiplexer)
		return new Demultiplexer(max_data_length, block_size)

	initialize(@, max_data_length, block_size)
	@_pending_blocks	= []

Demultiplexer:: =
	/**
	 * @param {!Uint8Array} block
	 */
	'feed' : (block) !->
		if @have_more_data()
			@_pending_blocks.push(block)
		else
			@_feed(block)
	/**
	 * @param {!Uint8Array} block
	 */
	_feed : (block) !->
		new_buffer	= new Uint8Array(@_buffer.length + block.length)
			..set(@_buffer)
			..set(block, @_buffer.length)
		@_buffer	= new_buffer
	/**
	 * @return {boolean}
	 */
	'have_more_data' : ->
		@_fill_buffer()
		@_have_more_data()
	/**
	 * @return {boolean}
	 */
	_have_more_data : ->
		if @_buffer.length <= @_block_size_header_bytes
			return false
		data_length	= uint_array_to_number(@_buffer.subarray(0, @_block_size_header_bytes))
		data_length != 0 && @_buffer.length >= @_block_size_header_bytes + data_length
	/**
	 * @return {Uint8Array}
	 */
	'get_data' : ->
		if !@have_more_data()
			return null
		data_length	= uint_array_to_number(@_buffer.subarray(0, @_block_size_header_bytes))
		data		= @_buffer.subarray(@_block_size_header_bytes, @_block_size_header_bytes + data_length)
		@_buffer	= @_buffer.subarray(@_block_size_header_bytes + data_length)
		data
	_fill_buffer : !->
		loop
			if @_have_more_data() || !@_pending_blocks.length
				break
			data_length	= uint_array_to_number(@_buffer.subarray(0, @_block_size_header_bytes))
			if !data_length
				@_buffer	= new Uint8Array(0)
			@_feed(@_pending_blocks.shift())

Object.defineProperty(Demultiplexer::, 'constructor', {enumerable: false, value: Demultiplexer})