Bookshelf = require 'bookshelf'
CheckIt = require 'checkit'
Schema = require '../src/'
init = require './init'

describe "Count", ->
    this.timeout 3000
    db = null
    User = null

    before co ->
        db = init.init()
        yield init.users()

        class User extends db.Model
            tableName: 'users'

        yield [
             new User(username: 'alice', flag: true, email: 'alice@bookstore').save()
             new User(username: 'bob', flag: true, email: 'bob@bookstore').save()
             new User(username: 'alan', flag: false).save()
        ]

    it 'counts the number of models in a collection', ->
        User.collection().count().should.become 3

    it 'optionally counts by column (excluding null values)', ->
        User.collection().count('email').should.become 2

    it 'counts a filtered query', ->
        User.collection().query('where', 'flag', '=', true).count().should.become 2
