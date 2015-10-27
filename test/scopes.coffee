Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
{StringField, BooleanField} = require '../src/fields'
{BelongsToMany} = require '../src/relations'
Scope = require '../src/scopes'

describe "Scopes", ->
    this.timeout 3000
    db = null
    User = null
    Group = null

    before co ->
        db = init.init()
        yield [
            init.users()
            init.groups()
        ]

    beforeEach ->
        class User extends db.Model
            tableName: 'users'

        class Group extends db.Model
            tableName: 'groups'

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

        it 'with count', ->
            User.flagged().count().then(parseInt).should.become 1

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

        it 'with count', ->
            User.flagged().nameStartsWith('a').count().then(parseInt).should.become 1

    describe 'on relations', ->
        beforeEach co ->
            User.schema [
                StringField 'username'

                Scope 'flagged', -> @where flag: true
                Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
            ]

            Group.schema [
                StringField 'name'

                BelongsToMany User
                BelongsToMany User, name: 'flaggedUsers', query: -> @flagged()
            ]

            users = yield [
                 new User(username: 'alice', flag: true).save()
                 new User(username: 'bob', flag: true).save()
                 new User(username: 'alan', flag: false).save()
            ]

            groups = yield [
                new Group(name: 'wheel').save()
                new Group(name: 'users').save()
            ]

            yield [
                # alice is wheel
                db.knex('groups_users').insert(user_id: users[0].id, group_id: groups[0].id)
                # bob and alan are users
                db.knex('groups_users').insert(user_id: users[1].id, group_id: groups[1].id)
                db.knex('groups_users').insert(user_id: users[2].id, group_id: groups[1].id)
            ]

        describe 'BelongsToMany', ->
            it 'fetch', co ->
                wheel = yield new Group(name: 'wheel').fetch()
                wheelUsers = yield wheel.$users.flagged().fetch()
                wheelUsers.should.be.an.instanceof db.Collection
                wheelUsers.length.should.equal 1
                wheelUsers.at(0).username.should.equal 'alice'

            it 'count', co ->
                wheel = yield new Group(name: 'wheel').fetch()
                wheel.$users.count().should.become 1

            it.skip 'scope in relation definition', co ->
                users = yield new Group(name: 'users').fetch()
                usersUsers = yield users.$flaggedUsers.fetch()
                usersUsers.should.be.an.instanceof db.Collection
                usersUsers.length.should.equal 1
                usersUsers.at(0).username.should.equal 'bob'

