describe 'Smoke test', ->
  it 'should work with "assert"', ->
    assert true

  it 'should work with "expect"', ->
    expect(undefined).to.be.undefined
  
  it 'should work with "should"', ->
    should.not.exist null
    
  it 'should work with "sinon"', ->
    stub = sinon.stub()
    stub()
    # Alternatives:
    #   sinon.assert.calledOnce stub
    #   assert stub.calledOnce
    #   expect(stub.calledOnce).to.be.true
    stub.calledOnce.should.be.true
    stub.calledTwice.should.be.false
  
  it 'should work with async code', (done) ->
    setTimeout done, 5
    
  describe 'fake timer', ->
    before ->
      @clock = sinon.useFakeTimers()
    after ->
      @clock.restore()
      
    it 'should run quickly', ->
      stub = sinon.stub()
      setTimeout stub, 5000
      stub.called.should.be.false
      @clock.tick 2500
      stub.called.should.be.false
      @clock.tick 2500
      stub.called.should.be.true

  it 'should be the right version'
