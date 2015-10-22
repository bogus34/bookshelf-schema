Bookshelf = require 'bookshelf'
Schema = require '../../src/'
init = require '../init'
Fields = require '../../src/fields'
Relations = require '../../src/relations'

{StringField} = Fields
{MorphOne, MorphTo} = Relations

describe "Relations", ->
    this.timeout 3000
    db = null
    User = null
    Tag = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            tag = yield new Tag(name: 'girl', tagable_id: alice.id, tagable_type: 'users').save()
            [alice, tag]

    before co ->
        db = init.init()
        yield [ init.users(), init.tags() ]

    describe 'MorphTo', ->
        beforeEach ->
            class User extends db.Model
                tableName: 'users'

            class Tag extends db.Model
                tableName: 'tags'
                @schema [
                    StringField 'name'
                    MorphTo 'tagable', [User]
                ]

            User.schema [
                StringField 'username'
                MorphOne Tag, 'tagable'
            ]

        afterEach -> init.truncate 'users', 'tags'

        it 'creates accessor', co ->
            [alice, tag] = yield fixtures.alice()
            tag.tagable.should.be.a 'function'
            yield tag.load 'tagable'
            tag.$tagable.should.be.an.instanceof User
            tag.$tagable.username.should.equal alice.username

        ensureAssigned = co (newUser, name) ->
            name ?= newUser.username
            [_, tag] = yield fixtures.alice()
            yield tag.$tagable.assign newUser
            tag = yield Tag.forge(id: tag.id).fetch(withRelated: 'tagable')
            tag.$tagable.username.should.equal name

        it 'can assign model', co ->
            bob = yield new User(username: 'bob').save()
            yield ensureAssigned bob
