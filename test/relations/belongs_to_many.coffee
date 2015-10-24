Bookshelf = require 'bookshelf'
Schema = require '../../src/'
init = require '../init'
Fields = require '../../src/fields'
Relations = require '../../src/relations'

{StringField} = Fields
{HasMany, BelongsToMany} = Relations

describe "Relations", ->
    this.timeout 3000
    db = null
    User = null
    Group = null

    fixtures =
        alice: ->
            new User(username: 'alice').save()
        groups: (names...) ->
            names.map (name) ->
                new Group(name: name).save()
        connect: (user, groups) ->
            groups.map (group) ->
                db.knex('groups_users').insert(user_id: user.id, group_id: group.id)

    before co ->
        db = init.init()
        yield [ init.users(), init.groups() ]

    describe 'BelongsToMany', ->
        beforeEach ->
            class Group extends db.Model
                tableName: 'groups'

            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username'
                    BelongsToMany Group
                ]

            Group.schema [
                StringField 'name'
                BelongsToMany User
            ]

        afterEach -> init.truncate 'users', 'groups', 'groups_users'

        it 'creates accessor', co ->
            [alice, groups] = yield [ fixtures.alice(), fixtures.groups('users') ]
            yield fixtures.connect alice, groups
            alice.groups.should.be.a 'function'
            yield alice.load 'groups'
            alice.$groups.should.be.an.instanceof db.Collection
            alice.$groups.at(0).name.should.equal 'users'

        it 'can assign list of models to relation', co ->
            [alice, [users, music, games]] = yield [
                fixtures.alice()
                fixtures.groups('users', 'music', 'games')
            ]
            yield fixtures.connect alice, [users, music]
            yield alice.$groups.assign [games, music]

            alice = yield User.forge(id: alice.id).fetch(withRelated: 'groups')

            alice.$groups.pluck('name').sort().should.deep.equal ['games', 'music']

        it 'can also assign plain objects and ids', co ->
            [alice, [users]] = yield [
                fixtures.alice()
                fixtures.groups('users')
            ]

            yield alice.$groups.assign [users.id, {name: 'games'}]
            alice = yield User.forge(id: alice.id).fetch(withRelated: 'groups')

            alice.$groups.pluck('name').sort().should.deep.equal ['games', 'users']

        it 'detach all related objects when empty list assigned', co ->
            [alice, [users]] = yield [
                fixtures.alice()
                fixtures.groups('users')
            ]
            yield fixtures.connect alice, [users]

            alice = yield User.forge(id: alice.id).fetch(withRelated: 'groups')
            alice.$groups.length.should.equal 1

            yield alice.$groups.assign []

            alice = yield User.forge(id: alice.id).fetch(withRelated: 'groups')
            alice.$groups.length.should.equal 0

        it 'fixes count method', co ->
            [alice, groups] = yield [
                fixtures.alice()
                fixtures.groups('users', 'music', 'games')
            ]
            yield fixtures.connect alice, groups[..1]
            yield [
                alice.$groups.count().should.become 2
                alice.$groups._originalCount().should.not.become 2
            ]

    describe 'onDestroy', ->
        beforeEach ->
            class Group extends db.Model
                tableName: 'groups'

            class User extends db.Model
                tableName: 'users'

        afterEach -> init.truncate 'users', 'groups', 'groups_users'

        it 'can cascade-destroy dependent models', co ->
            User.schema [
                BelongsToMany Group, onDestroy: 'cascade'
            ]

            [alice, groups] = yield [
                fixtures.alice()
                fixtures.groups('users', 'music', 'games')
            ]
            aliceId = alice.id
            yield fixtures.connect alice, groups[..1]
            yield alice.$groups.count().should.become 2
            yield alice.destroy()

            yield [
                db.knex('groups_users').where(user_id: aliceId).count('*').should.become [{'count(*)': 0}]
                Group.forge(id: groups[2].id).fetch().should.eventually.have.property 'id'
            ]

        it 'can reject destroy when there is any dependent models', co ->
            User.schema [
                BelongsToMany Group, onDestroy: 'reject'
            ]

            [alice, groups] = yield [
                fixtures.alice()
                fixtures.groups('users', 'music', 'games')
            ]
            yield fixtures.connect alice, groups[..1]
            yield alice.destroy().should.be.rejected
            yield alice.$groups.assign []
            alice.destroy().should.be.fulfilled

        it 'can detach dependend models on destroy', co ->
            User.schema [
                BelongsToMany Group, onDestroy: 'detach'
            ]

            [alice, groups] = yield [
                fixtures.alice()
                fixtures.groups('users', 'music', 'games')
            ]
            aliceId = alice.id
            yield fixtures.connect alice, groups[..1]
            yield alice.destroy().should.be.fulfilled

            db.knex('groups_users').where(user_id: aliceId).count('*').should.become [{'count(*)': 0}]
