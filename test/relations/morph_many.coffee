Bookshelf = require 'bookshelf'
Schema = require '../../src/'
init = require '../init'
Fields = require '../../src/fields'
Relations = require '../../src/relations'

{StringField} = Fields
{MorphMany, MorphTo} = Relations

describe "Relations", ->
    this.timeout 3000
    db = null
    User = null
    Tag = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            tags = yield [
                new Tag(name: 'girl', tagable_id: alice.id, tagable_type: 'users').save()
                new Tag(name: 'redhead', tagable_id: alice.id, tagable_type: 'users').save()
            ]
            [alice, tags]

    before co ->
        db = init.init()
        yield [ init.users(), init.tags() ]

    describe 'MorphMany', ->
        beforeEach ->
            class Tag extends db.Model
                tableName: 'tags'

            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username'
                    MorphMany Tag, 'tagable'
                ]

            Tag.schema [
                StringField 'name'
                MorphTo 'tagable', [User]
            ]

        afterEach -> init.truncate 'users', 'tags'

        it 'creates accessor', co ->
            [alice, _] = yield fixtures.alice()
            alice.tags.should.be.a 'function'
            yield alice.load 'tags'
            alice.$tags.should.be.an.instanceof db.Collection

        it 'can assign list of models to relation', co ->
            [alice, [girl, redhead]] = yield fixtures.alice()

            bob = yield new User(username: 'bob').save()
            boy = yield new Tag(name: 'boy').save()

            yield bob.$tags.assign [boy, redhead]

            [bob, alice] = yield [
                 User.forge(id: bob.id).fetch(withRelated: 'tags')
                 User.forge(id: alice.id).fetch(withRelated: 'tags')
            ]
            bob.$tags.length.should.equal 2
            bob.$tags.pluck('name').sort().should.deep.equal ['boy', 'redhead']
            alice.$tags.length.should.equal 1
            alice.$tags.at(0).name.should.equal 'girl'

        it 'can also assign plain objects and ids', co ->
            [alice, [girl, redhead]] = yield fixtures.alice()

            bob = yield new User(username: 'bob').save()
            yield bob.$tags.assign [{name: 'boy'}, redhead.id]
            [bob, alice] = yield [
                 User.forge(id: bob.id).fetch(withRelated: 'tags')
                 User.forge(id: alice.id).fetch(withRelated: 'tags')
            ]
            bob.$tags.length.should.equal 2
            bob.$tags.pluck('name').sort().should.deep.equal ['boy', 'redhead']

        it 'detach all related objects when empty list assigned', co ->
            [alice, _] = yield fixtures.alice()

            yield Tag.where(tagable_id: alice.id, tagable_type: 'users').count().then(parseInt).should.become 2
            yield alice.$tags.assign []
            Tag.where(tagable_id: alice.id, tagable_type: 'users').count().then(parseInt).should.become 0

