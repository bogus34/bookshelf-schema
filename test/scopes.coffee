Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
{StringField, BooleanField} = require '../src/fields'
Scope = require '../src/scopes'

describe "Scopes", ->
    this.timeout 3000
    db = null
    User = null

    before ->
        db = init.init()
        init.users()

    beforeEach ->
        User = class extends db.Model
            tableName: 'users'

    afterEach -> init.truncate 'users'

    it 'creates scopes as a functions', ->
        User.schema [
            Scope 'flagged', ->
        ]

        expect(User.flagged).to.be.a.function
        expect(User::flagged).to.be.a.function

    describe 'applies scope', ->
        beforeEach co ->
            User.schema [
                StringField 'username'
                BooleanField 'flag'
                Scope 'flagged', -> @where flag: true
            ]

            yield [
                 new User(username: 'alice', flag: true).save()
                 new User(username: 'bob', flag: false).save()
            ]

        it 'with fetchAll', co ->
            flagged = yield User.flagged().fetchAll()
            flagged.should.be.an.instanceof db.Collection
            flagged.length.should.equal 1
            flagged.at(0).flag.should.be.true

        it 'with fetch', co ->
            flagged = yield User.flagged().fetch()
            flagged.should.be.an.instanceof User
            flagged.flag.should.be.true

    describe 'applies chained scopes', ->
        beforeEach co ->
            User.schema [
                StringField 'username'
                BooleanField 'flag'
                Scope 'flagged', -> @where flag: true
                Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
            ]

            yield [
                 new User(username: 'alice', flag: true).save()
                 new User(username: 'bob', flag: true).save()
                 new User(username: 'alan', flag: false).save()
            ]

        it 'with fetchAll', co ->
            result = yield User.flagged().nameStartsWith('a').fetchAll()
            result.should.be.an.instanceof db.Collection
            result.length.should.equal 1
            result.at(0).username.should.equal 'alice'

        it 'with fetch', co ->
            result = yield User.flagged().nameStartsWith('a').fetch()
            result.should.be.an.instanceof User
            result.username.should.equal 'alice'
