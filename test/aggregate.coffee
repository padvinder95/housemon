should = require('chai').Should()

aggregator = require '../briqs/storage/aggregator'

verifyObject = (obj, props) ->
  for k,v in props
    obj.should.have.property k, v

describe 'aggregator', ->

  it 'should have a create function', ->
    should.exist(aggregator.create)

  it 'should have a pack function', ->
    should.exist(aggregator.pack)

  it 'should have an unpack function', ->
    should.exist aggregator.unpack

  describe '.create', ->
    a = aggregator.create()
    
    it 'should have count, mean, min, max, m2 members', ->
      a.should.have.keys ['count', 'mean', 'min', 'max', 'm2']

    it 'should have zero values', ->
      verifyObject a, {count:0, mean:0, min:0, max:0, m2:0}

    it 'should have an update member', ->
      a.should.respondTo 'update'

    it 'should have an extract member', ->
      a.should.respondTo 'extract'

  describe '#extract', ->
    e = aggregator.create().extract()

    it '.sdev should be 0', ->
      e.should.have.property 'sdev', 0

    it '.m2 should not exist', ->
      e.should.not.have.property 'm2'

  describe '#update', ->

    it 'is called once', ->
      a = aggregator.create()
      a.update 9
      e = a.extract()
      verifyObject e, {count: 1, mean: 9, min: 9, max: 9, sdev: 0}

    it 'is called twice', ->
      a = aggregator.create()
      a.update 9
      a.update 1
      e = a.extract()
      verifyObject e, {count: 2, mean: 5, min: 1, max: 9}
      e.sdev.should.be.closeTo 5.65, 0.01

    it 'is called 3 times with same value', ->
      a = aggregator.create()
      a.update 9
      a.update 9
      a.update 9
      e = a.extract()
      verifyObject e, {count: 3, mean: 9, min: 9, max: 9, sdev: 0}

  describe '.pack', ->
    e = aggregator.create().extract()
    p = aggregator.pack e

    it 'should return a Bytes object', ->
      (p instanceof Buffer).should.be.true

    it 'should unpack to the proper values', ->
      u = aggregator.unpack p
      verifyObject u, {count: 0, mean: 0, min: 0, max: 0, sdev: 0}

    it 'should work with other values', ->
      a = aggregator.create()
      a.update 9
      a.update 1
      u = aggregator.unpack aggregator.pack a.extract()
      # note that sdev 5.65 has been rounded up by packing
      verifyObject u, {count: 2, mean: 5, min: 1, max: 9, sdev: 6}
