Bookshelf = require 'bookshelf'
CheckIt = require 'checkit'
Schema = require '../src/'
init = require './init'
F = require '../src/fields'

describe "Fields", ->
    this.timeout 3000
    db = null

    define = (fields) ->
        class User extends db.Model
            tableName: 'users'
            @schema fields

    before ->
        db = init.init()
        init.users()

    afterEach -> init.truncate 'users'

    describe 'Any field', ->
        it 'may be required', co ->
            User = define [F.StringField 'username', required: true]
            User.__bookshelf_schema.validations.username.should.deep.equal ['required']

            yield [
                new User().validate().should.be.rejected
                new User(username: 'alice').validate().should.be.fulfilled
            ]

    describe 'StringField', ->
        it 'validates min_length and max_length', co ->
            User = define [F.StringField 'username', min_length: 5, max_length: 10]
            User.__bookshelf_schema.validations.username.should.deep.equal ['minLength:5', 'maxLength:10']

            yield [
                new User(username: 'foo').validate().should.be.rejected
                new User(username: 'Some nickname that is longer then 10 characters').validate().should.be.rejected
                new User(username: 'justfine').validate().should.be.fulfilled
            ]

        it 'uses additional names for length restrictions', ->
            User = define [F.StringField 'username', minLength: 5, maxLength: 10]
            User.__bookshelf_schema.validations.username.should.deep.equal ['minLength:5', 'maxLength:10']

    describe 'EmailField', ->
        it 'validates email', co ->
            User = define [F.EmailField 'email']
            User.__bookshelf_schema.validations.email.should.deep.equal ['email']

            yield [
                new User(email: 'foo').validate().should.be.rejected
                new User(email: 'foo@bar.com').validate().should.be.fulfilled
            ]

    describe 'EncryptedStringField', ->
        sha1 = require 'sha1'
        it 'save its value encrypted', co ->
            User = define [F.EncryptedStringField 'password', algorithm: sha1]

            alice = yield new User(password: 'password').save()
            alice.password.should.equal 'password'
            alice = yield User.forge(id: alice.id).fetch()
            expect(alice.password.plain).to.be.null
            alice.password.verify('password').should.be.true

        it 'saves new value encrypted', co ->
            User = define [F.EncryptedStringField 'password', algorithm: sha1]

            alice = yield new User(password: 'password').save()
            alice.password = 'password2'
            yield alice.save()
            alice = yield User.forge(id: alice.id).fetch()
            alice.password.verify('password2').should.be.true

        it "doesn't reencrypt it on save", co ->
            User = define [F.EncryptedStringField 'password', algorithm: sha1]

            alice = yield new User(password: 'password').save()
            alice = yield User.forge(id: alice.id).fetch()
            check = alice.password.encrypted
            alice.set('username', 'alice')
            yield alice.save()
            alice = yield User.forge(id: alice.id).fetch()
            alice.password.encrypted.should.equal check

        it 'works w/o salt', co ->
            User = define [F.EncryptedStringField 'password', algorithm: sha1, salt: false]

            alice = yield new User(password: 'password').save()
            alice.password.should.equal 'password'
            alice = yield User.forge(id: alice.id).fetch()
            expect(alice.password.plain).to.be.null
            alice.password.verify('password').should.be.true

        it 'validates length against plain value', co ->
            User = define [F.EncryptedStringField 'password', algorithm: sha1, minLength: 8, maxLength: 10]

            yield [
                new User(password: 'foo').validate().should.be.rejected
                new User(password: 'password').validate().should.be.fulfilled
                new User(password: 'password1234567890').validate().should.be.rejected
            ]

            alice = yield new User(password: 'password').save()
            alice = yield User.forge(id: alice.id).fetch()
            yield alice.validate().should.be.fulfilled

    describe 'IntField', ->
        it 'validates integers', co ->
            User = define [F.IntField 'code']
            User.__bookshelf_schema.validations.code.should.deep.equal ['integer']

            yield [
                new User(code: 'foo').validate().should.be.rejected
                new User(code: '10foo').validate().should.be.rejected
                new User(code: 10.5).validate().should.be.rejected
                new User(code: 10).validate().should.be.fulfilled
                new User(code: '10').validate().should.be.fulfilled
                new User(code: '-10').validate().should.be.fulfilled
            ]

        it 'validates natural', co ->
            User = define [F.IntField 'code', natural: true]
            User.__bookshelf_schema.validations.code.should.deep.equal ['integer', 'natural']

            yield [
                new User(code: 10).validate().should.be.fulfilled
                new User(code: -10).validate().should.be.rejected
                new User(code: '-10').validate().should.be.rejected
            ]

        it 'validates bounds', co ->
            User = define [F.IntField 'code', greater_than: 1, less_than: 10]
            User.__bookshelf_schema.validations.code.should.deep.equal ['integer', 'greaterThan:1', 'lessThan:10']

            yield [
                new User(code: 5).validate().should.be.fulfilled
                new User(code: 1).validate().should.be.rejected
                new User(code: 10).validate().should.be.rejected
            ]

        it 'keeps nulls', co ->
            User = define [F.IntField 'code']

            user = yield new User(code: null).save()
            expect(user.code).to.be.null
            user = yield User.forge(id: user.id).fetch()
            expect(user.code).to.be.null

    describe 'FloatField', ->
        it 'validates floats', co ->
            User = define [F.FloatField 'code']
            User.__bookshelf_schema.validations.code.should.deep.equal ['numeric']

            yield [
                new User(code: 'foo').validate().should.be.rejected
                new User(code: '10foo').validate().should.be.rejected
                new User(code: 10.5).validate().should.be.fulfilled
                new User(code: 10).validate().should.be.fulfilled
                new User(code: '10.5').validate().should.be.fulfilled
                new User(code: '-10.5').validate().should.be.fulfilled
            ]

        it 'keeps nulls', co ->
            User = define [F.FloatField 'code']

            user = yield new User(code: null).save()
            expect(user.code).to.be.null
            user = yield User.forge(id: user.id).fetch()
            expect(user.code).to.be.null

    describe 'BooleanField', ->
        it 'stores boolean values', co ->
            User = define [F.BooleanField 'flag']
            user = yield new User(flag: 'some string').save()
            user = yield new User(id: user.id).fetch()
            user.flag.should.be.true

    describe 'DateTimeField', ->
        it 'stores Date objects', co ->
            User = define [F.DateTimeField 'last_login']
            date = new Date('2013-09-25T15:00:00.000Z')
            user = yield new User(last_login: date).save()
            user = yield new User(id: user.id).fetch()
            user.last_login.should.be.an.instanceof Date
            user.last_login.toISOString().should.equal date.toISOString()

        it 'validates date', co ->
            User = define [F.DateTimeField 'last_login']

            yield [
                new User(last_login: new Date()).validate().should.be.fulfilled
                new User(last_login: new Date().toUTCString()).validate().should.be.fulfilled
                new User(last_login: '1/1/1').validate().should.be.fulfilled
                new User(last_login: 'foobar').validate().should.be.rejected
            ]

        it 'keeps nulls', co ->
            User = define [F.DateTimeField 'last_login']

            user = yield new User(last_login: null).save()
            expect(user.last_login).to.be.null
            user = yield User.forge(id: user.id).fetch()
            expect(user.last_login).to.be.null

    describe 'DateField', ->
        truncate_date = (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate())

        it 'stores Date objects', co ->
            User = define [F.DateField 'birth_date']
            date = new Date('2013-09-25T15:00:00.000Z')
            user = yield new User(birth_date: date).save()
            user = yield new User(id: user.id).fetch()
            user.birth_date.should.be.an.instanceof Date
            user.birth_date.toISOString().should.equal truncate_date(date).toISOString()

        it 'validates date', co ->
            User = define [F.DateField 'birth_date']

            yield [
                new User(birth_date: new Date()).validate().should.be.fulfilled
                new User(birth_date: new Date().toUTCString()).validate().should.be.fulfilled
                new User(birth_date: '1/1/1').validate().should.be.fulfilled
                new User(birth_date: 'foobar').validate().should.be.rejected
            ]

        it 'keeps nulls', co ->
            User = define [F.DateField 'birth_date']

            user = yield new User(birth_date: null).save()
            expect(user.birth_date).to.be.null
            user = yield User.forge(id: user.id).fetch()
            expect(user.birth_date).to.be.null

    describe 'JSONField', ->
        it 'stores JSON objects', co ->
            User = define [F.JSONField 'additional_data']

            data  =
                nickname: 'bogus'
                interests: ['nodejs', 'photography', 'tourism']

            user = yield new User(additional_data: data).save()
            user = yield new User(id: user.id).fetch()
            user.additional_data.should.deep.equal data

        it 'validates JSON', co ->
            User = define [F.JSONField 'additional_data']

            yield [
                new User(additional_data: {foo: 'bar'}).validate().should.be.fulfilled
                new User(additional_data: JSON.stringify(foo: 'bar')).validate().should.be.fulfilled
                new User(additional_data: 42).validate().should.be.rejected
                new User(additional_data: 'not a json').validate().should.be.rejected
            ]

