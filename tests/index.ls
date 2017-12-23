/**
 * @package   Fixed size multiplexer
 * @author    Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @copyright Copyright (c) 2017, Nazar Mokrynskyi
 * @license   MIT License, see license.txt
 */
crypto	= require('crypto')
lib		= require('..')
test	= require('tape')

max_data_length	= 2**16 - 1
block_size		= 128

test('Basic usage', (t) !->
	t.plan(15)

	mux		= lib.Multiplexer(max_data_length, block_size)
	demux	= lib.Demultiplexer(max_data_length, block_size)

	data1	= crypto.randomBytes(32)
	data2	= crypto.randomBytes(256)
	data3	= crypto.randomBytes(256)

	t.notOk(mux.have_more_blocks(), 'No blocks initially')
	t.notOk(demux.have_more_data(), 'No data initially')

	mux.feed(data1)
	mux.feed(data2)

	demux.feed(mux.get_block())
	t.ok(mux.have_more_blocks(), 'Some blocks left initially')
	t.ok(demux.have_more_data(), 'There is one piece of data')

	data	= demux.get_data()
	t.equal(Buffer.from(data).toString('hex'), data1.toString('hex'), 'Got correct data #1')

	t.notOk(demux.have_more_data(), 'No more data yet')

	while mux.have_more_blocks()
		t.pass('One more chunk')
		demux.feed(mux.get_block())

	block	= mux.get_block()
	t.equal((new Buffer(block_size)).toString('hex'), Buffer.from(block).toString('hex'), 'Multiplexer returns empty blocks if no data present')
	demux.feed(block)

	mux.feed(data3)

	while mux.have_more_blocks()
		t.pass('One more chunk')
		demux.feed(mux.get_block())

	t.ok(demux.have_more_data(), 'Have more data')

	data	= demux.get_data()
	t.equal(Buffer.from(data).toString('hex'), data2.toString('hex'), 'Got correct data #2')

	data	= demux.get_data()
	t.equal(Buffer.from(data).toString('hex'), data3.toString('hex'), 'Got correct data #3')
)

test('Alternating feed', (t) !->
	t.plan(7)

	mux		= lib.Multiplexer(max_data_length, block_size)
	demux	= lib.Demultiplexer(max_data_length, block_size)

	data1	= crypto.randomBytes(125)
	data2	= crypto.randomBytes(124)

	mux.feed(data1)

	t.ok(mux.have_more_blocks(), 'There are blocks #1')

	demux.feed(mux.get_block())

	t.ok(demux.have_more_data(), 'There are data #1')
	t.equal(Buffer.from(demux.get_data()).toString('hex'), data1.toString('hex'), 'Got correct data #1')

	mux.feed(data2)

	t.ok(mux.have_more_blocks(), 'There are blocks #2')

	demux.feed(mux.get_block())

	t.ok(demux.have_more_data(), 'There are data #2')
	t.equal(Buffer.from(demux.get_data()).toString('hex'), data2.toString('hex'), 'Got correct data #2')

	t.notOk(mux.have_more_blocks(), 'There are no more blocks')
)
