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
        User = class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', minLength: 3, maxLength: 15
                EmailField 'email'
            ]
        init.users()

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
        f = spy -> false
        User.__bookshelf_schema.validations.username.push f

        e = yield new User(username: 'bogus').save().should.be.rejected
        e.should.be.an.instanceof CheckIt.Error
        f.should.have.been.called

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
                StringField 'username', validations: [{
                    rule: 'minLength:5',
                    message: '{{label}}: foo',
                    label: 'foo'
                }]
            ]

        e = yield new User(username: 'bar').validate().should.be.rejected
        e.get('username').message.should.equal 'foo: foo'

    describe 'Custom error messages', ->
        it 'uses provided messages', co ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'foo', min_length: {value: 10, message: 'foo'}
                ]

            e = yield new User(foo: 'bar').validate().should.be.rejected
            e.get('foo').message.should.equal 'foo'

        it 'uses field default error message and label', co ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username', min_length: 10, message: '{{label}}: foo', label: 'foo'
                ]

            e = yield new User(username: 'bar').validate().should.be.rejected
            e.get('username').message.should.equal 'foo: foo'

        it 'user field error message and label for field type validation', co ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    EmailField 'email', message: '{{label}}: foo', label: 'foo'
                ]

            e = yield new User(email: 'bar').validate().should.be.rejected
            e.get('email').message.should.equal 'foo: foo'

        it 'can use i18n for messages', co ->
            db2 = Bookshelf db.knex
            db2.plugin Schema(
                language: 'ru',
                messages: {email: 'Поле {{label}} должно содержать email-адрес'}
            )

            class User extends db2.Model
                tableName: 'users'
                @schema [
                    EmailField 'email'
                ]

            e = yield new User(email: 'bar').validate().should.be.rejected
            e.get('email').message.should.equal 'Поле email должно содержать email-адрес'
