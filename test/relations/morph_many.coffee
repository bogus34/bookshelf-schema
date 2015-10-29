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
        describe 'plain', ->
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

            it 'fixes count method', co ->
                [alice, tags] = yield fixtures.alice()
                boy = yield new Tag(name: 'boy').save()
                yield [
                    alice.$tags.count().should.become 2
                ]

        describe 'onDestroy', ->
            beforeEach ->
                class User extends db.Model
                    tableName: 'users'

                class Tag extends db.Model
                    tableName: 'tags'

            afterEach -> init.truncate 'users', 'tags'

            it 'can cascade-destroy dependent models', co ->
                User.schema [
                    MorphMany Tag, 'tagable', onDestroy: 'cascade'
                ]

                [alice, tags] = yield fixtures.alice()
                boy = yield new Tag(name: 'boy').save()

                yield alice.$tags.count().should.become 2
                aliceId = alice.id
                yield alice.destroy().should.be.fulfilled

                yield [
                     Tag.where(tagable_id: aliceId, tagable_type: 'users').count().then(parseInt).should.become 0
                     expect(new Tag(id: boy.id).fetch()).not.to.be.null
                ]

            it 'can reject destroy when there is any dependent models', co ->
                User.schema [
                    MorphMany Tag, 'tagable', onDestroy: 'reject'
                ]

                [alice, tags] = yield fixtures.alice()
                yield alice.destroy().should.be.rejected
                yield alice.$tags.assign []
                alice.destroy().should.be.fulfilled

            it 'can detach dependend models on destroy', co ->
                User.schema [
                    MorphMany Tag, 'tagable', onDestroy: 'detach'
                ]

                [alice, tags] = yield fixtures.alice()
                tagIds = (tag.id for tag in tags)
                yield alice.destroy().should.be.fulfilled

                Tag.collection().query (qb) ->
                    qb.whereIn 'id', tagIds
                .fetch()
                .then (c) -> c.pluck 'tagable_id'
                .should.become [null, null]
