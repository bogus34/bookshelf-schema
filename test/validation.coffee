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

    beforeEach ->
        class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', minLength: 3, maxLength: 15
                EmailField 'email'
            ]

    it 'should create array of validations', ->
        User.__bookshelf_schema.validations.should.deep.equal
            username: ['string', 'minLength:3', 'maxLength:15']
            email: ['string', 'email']

    it 'should validate models', co ->
        yield [
            new User(username: 'bogus').validate().should.be.fulfilled
            new User(username: 'bogus', email: 'foobar').validate().should.be.rejected
        ]

    it 'should run validations on save', co ->
        spy.on User.prototype, 'validate'
        user = new User(username: 'alice')
        yield user.save()
        user.validate.should.have.been.called()

    it "shouldn't apply validation if plugin initialized with option validation: false", co ->
        db2 = Bookshelf db.knex
        db2.plugin Schema(validation: false)

        class User extends db2.Model
            tableName: 'users', validations: [ -> false ]

        spy.on User.prototype, 'validate'
        user = new User(username: 'alice')
        yield user.save()
        user.validate.should.not.have.been.called()
        yield user.validate().should.be.fulfilled

    it "shouldn't apply validation when saved with option validation: false", co ->
        f = spy -> false
        class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', validations: [ f ]
            ]
        user = new User(username: 'alice')
        yield user.save(null, validation: false)
        f.should.not.have.been.called()

    it "when patching should accept validation to passed attributes only", co ->
        f = spy -> true
        g = spy -> true
        h = spy -> false
        class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', validations: [ f ]
                StringField 'password', validations: [g]
                StringField 'email', validations: [ h ], required: true
            ]

        user = yield User.forge(username: 'alice').save(null, validation: false)
        user.email = 'foobar'

        yield user.save({username: 'annie', password: 'secret'}, {patch: true})

        f.should.have.been.called()
        g.should.have.been.called()
        h.should.not.have.been.called()

        f.reset()
        g.reset()

        try
            yield user.save({username: 'annie', password: 'secret'}, {patch: false})
        catch
            # pass

        f.should.have.been.called()
        g.should.have.been.called()
        h.should.have.been.called()

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
