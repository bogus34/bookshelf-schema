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
            tag = yield new Tag(tag: 'girl', tagable_id: alice.id, tagable_type: 'users').save()
            [alice, tag]

    before co ->
        db = init.init()
        yield [ init.users(), init.tags() ]

    describe 'MorphOne', ->
        beforeEach ->
            class User extends db.Model
                tableName: 'users'

            class Tag extends db.Model
                tableName: 'tags'
                @schema [
                    StringField 'tag'
                    #MorphTo 'tagable', User
                ]

            User.schema [
                StringField 'username'
                MorphOne Tag, 'tagable'
            ]

        it.only 'creates accessor', co ->
            [alice, tag] = yield fixtures.alice()
            alice.tag.should.be.a 'function'
            yield alice.load 'tag'
            alice.$tag.should.be.an.instanceof Tag
            alice.$tag.tag.should.equal tag.tag
