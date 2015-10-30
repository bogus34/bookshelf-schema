Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
Listen = require '../src/listen'

describe 'Listen', ->
    this.timeout 3000
    db = null
    User = null

    before ->
        db = init.init()
        init.users()

    beforeEach ->
        class User extends db.Model
            tableName: 'users'

    it 'can add functions as listeners', co ->
        f1 = spy()
        f2 = spy()
        f3 = spy()
        User.schema [
            Listen 'saved', f1, f2
        ]

        yield new User(username: 'alice').save()
        f1.should.be.called.once
        f2.should.be.called.once
        f3.should.not.be.called()

    it 'can add listeners by name', co ->
        User::f1 = spy()
        User::f2 = spy()
        User::f3 = spy()
        User.schema [
            Listen 'saved', 'f1', 'f2'
        ]

        u = yield new User(username: 'alice').save()
        u.f1.should.be.called.once
        u.f2.should.be.called.once
        u.f3.should.not.be.called()

    it 'can check for a condition', co ->
        f1 = spy()
        f2 = spy()
        f3 = spy()
        f4 = spy()
        User::checkTrue = -> true
        User::checkFalse = -> false
        User.schema [
            Listen 'saved', f1, condition: -> true
            Listen 'saved', f2, condition: -> false
            Listen 'saved', f3, condition: 'checkTrue'
            Listen 'saved', f3, condition: 'checkFalse'
        ]

        yield new User(username: 'alice').save()
        f1.should.have.been.called.once
        f3.should.have.been.called.once
        f2.should.not.have.been.called()
        f4.should.not.have.been.called()
