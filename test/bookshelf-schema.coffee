Knex = require 'knex'
Bookshelf = require 'bookshelf'
init = require './init'
Schema = require '../src/'
Fields = require '../src/fields'

describe "Bookshelf schema", ->
    this.timeout 3000
    db = null

    before ->
        db = init.init()

    it 'can apply schema with Model.extend', ->
        User = db.Model.extend {
            tableName: 'users'
        }, {
            schema: [
                Fields.StringField 'username'
                Fields.IntField 'age'
                Fields.EmailField 'email'
            ]
        }

        User.prototype.hasOwnProperty('username').should.be.true
        User.prototype.hasOwnProperty('age').should.be.true
        User.prototype.hasOwnProperty('email').should.be.true

    it 'can apply schema with coffeescript @schema static method', ->
        class User extends db.Model
            tableName: 'users'
            @schema [
                Fields.StringField 'username'
                Fields.IntField 'age'
                Fields.EmailField 'email'
            ]

        User.prototype.hasOwnProperty('username').should.be.true
        User.prototype.hasOwnProperty('age').should.be.true
        User.prototype.hasOwnProperty('email').should.be.true

