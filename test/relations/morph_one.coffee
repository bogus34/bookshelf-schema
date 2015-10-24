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

    describe 'MorphOne', ->
        beforeEach ->
            class User extends db.Model
                tableName: 'users'

            class Tag extends db.Model
                tableName: 'tags'
                @schema [
                    StringField 'name'
                    MorphTo 'tagable', User
                ]

            User.schema [
                StringField 'username'
                MorphOne Tag, 'tagable'
            ]

        afterEach -> init.truncate 'users', 'tags'

        it 'creates accessor', co ->
            [alice, tag] = yield fixtures.alice()
            alice.tag.should.be.a 'function'
            yield alice.load 'tag'
            alice.$tag.should.be.an.instanceof Tag
            alice.$tag.name.should.equal tag.name

        ensureAssigned = (newTag, name) ->
            name ?= newTag.name
            [alice, tag] = yield fixtures.alice()
            yield alice.$tag.assign newTag
            [alice, tag] = yield [
                 User.forge(id: alice.id).fetch(withRelated: 'tag')
                 Tag.forge(id: tag.id).fetch()
            ]
            alice.$tag.name.should.equal name
            expect(tag.get('tagable_id')).to.be.null
            expect(tag.get('tagable_type')).to.be.null

        it 'can assign model', co ->
            tag2 = yield new Tag(name: 'redhead').save()
            yield ensureAssigned tag2

        it 'can assign plain objects', -> ensureAssigned name: 'redhead'

        it 'can assign by id', co ->
            tag2 = yield new Tag(name: 'redhead').save()
            yield ensureAssigned tag2.id, tag2.name

    describe 'onDestroy', ->
        beforeEach ->
            class User extends db.Model
                tableName: 'users'

            class Tag extends db.Model
                tableName: 'tags'
                @schema [
                    MorphTo 'tagable', [User]
                ]

        afterEach -> init.truncate 'users', 'tags'

        it 'can cascade-destroy dependent models', co ->
            User.schema [
                MorphOne Tag, 'tagable', onDestroy: 'cascade'
            ]

            [alice, tag] = yield fixtures.alice()
            tag2 = yield new Tag(name: 'redhead').save()

            yield alice.destroy().should.be.fulfilled

            [tag, tag2] = yield [
                new Tag(id: tag.id).fetch()
                new Tag(id: tag2.id).fetch()
            ]

            expect(tag).to.be.null
            expect(tag2).not.to.be.null

        it 'can reject destroy when there id dependent model', co ->
            User.schema [
                MorphOne Tag, 'tagable', onDestroy: 'reject'
            ]

            [alice, _] = yield fixtures.alice()
            yield alice.destroy().should.be.rejected
            yield alice.$tag.assign null
            alice.destroy().should.be.fulfilled

        it 'can detach dependent models on destroy', co ->
            User.schema [
                MorphOne Tag, 'tagable', onDestroy: 'detach'
            ]

            [alice, tag] = yield fixtures.alice()
            yield alice.destroy().should.be.fulfilled

            tag = yield new Tag(id: tag.id).fetch()
            expect(tag.tagable_id).to.be.null
            expect(tag.tagable_type).to.be.null
