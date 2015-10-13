Bookshelf = require 'bookshelf'
CheckIt = require 'checkit'
Schema = require '../src/'
init = require './init'
Fields = require '../src/fields'
{StringField, IntField, EmailField} = Fields

describe "Validation", ->
    this.timeout 3000
    db = null
    User = null

    before ->
        db = init.init()
        init.users()
        User = class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', minLength: 3, maxLength: 15
                EmailField 'email'
            ]

    it 'should create array of validations', ->
        User.__bookshelf_schema.validations.should.deep.equal
            username: ['minLength:3', 'maxLength:15']
            email: ['email']

    it 'should validate models', co ->
        yield [
            new User(username: 'bogus').validate().should.be.fulfilled
            new User(username: 'bogus', email: 'foobar').validate().should.be.rejected
        ]

    it 'should run validations on save', co ->
        validationCalled = false
        f = ->
            validationCalled = true
            false
        User.__bookshelf_schema.validations.username.push f

        e = yield new User(username: 'bogus').save().should.be.rejected
        e.should.be.an.instanceof CheckIt.Error
        validationCalled.should.be.true

    it "shouldn't apply validation if plugin initialized with option validation: false", co ->
        db2 = Bookshelf db.knex
        db2.plugin Schema(validation: false)

        class User extends db2.Model
            tableName: 'users'
            @schema [
                StringField 'username', minLength: 3, maxLength: 15
            ]

        user = new User(username: 'x')

        yield [
            user.validate().should.be.fulfilled
            user.save().should.be.fulfilled
        ]

    it 'accepts custom validation rules like Checkit do', co ->
        class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', validations: [{rule: 'minLength:5', message: '{{label}}: foo', label: 'foo'}]
            ]

        e = yield new User(username: 'bar').validate().should.be.rejected
        e.get('username').message.should.equal 'foo: foo'
