Bookshelf = require 'bookshelf'
Schema = require '../../src/'
init = require '../init'
Fields = require '../../src/fields'
Relations = require '../../src/relations'

{StringField} = Fields
{HasMany, BelongsTo} = Relations

describe "Relations", ->
    this.timeout 3000
    db = null
    User = null
    Photo = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            photos = yield [
                new Photo(filename: 'photo1.jpg', user_id: alice.id).save()
                new Photo(filename: 'photo2.jpg', user_id: alice.id).save()
            ]
            [alice, photos]

    before co ->
        db = init.init()
        yield [ init.users(), init.photos() ]

    describe 'HasMany', ->
        beforeEach ->
            class Photo extends db.Model
                tableName: 'photos'

            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username'
                    HasMany Photo
                ]

            Photo.schema [
                StringField 'filename'
                BelongsTo User
            ]

        afterEach co ->
            yield [ db.knex('users').truncate(), db.knex('photos').truncate() ]

        it 'creates accessor', co ->
            [alice, _] = yield fixtures.alice()
            alice.photos.should.be.a 'function'
            yield alice.load 'photos'
            alice.$photos.should.be.an.instanceof db.Collection
            alice.$photos.at(0).user_id.should.be.equal alice.id

        it 'can assign list of models to relation', co ->
            [alice, [photo1, photo2]] = yield fixtures.alice()

            bob = yield new User(username: 'bob').save()
            photo3 = yield new Photo(filename: 'photo3.jpg', user_id: bob.id).save()

            yield bob.$photos.assign [photo1]

            bob = yield User.forge(id: bob.id).fetch(withRelated: 'photos')
            alice = yield User.forge(id: alice.id).fetch(withRelated: 'photos')
            bob.$photos.length.should.equal 1
            bob.$photos.at(0).id.should.equal photo1.id
            alice.$photos.length.should.equal 1
            alice.$photos.at(0).id.should.equal photo2.id

        it 'can also assign plain objects and ids', co ->
            [alice, [photo1, photo2]] = yield fixtures.alice()

            bob = yield new User(username: 'bob').save()
            yield bob.$photos.assign [{filename: 'photo3.jpg'}, photo1.id]
            [bob, alice] = yield [
                 User.forge(id: bob.id).fetch(withRelated: 'photos')
                 User.forge(id: alice.id).fetch(withRelated: 'photos')
            ]
            bob.$photos.length.should.equal 2
            bob.$photos.pluck('filename').sort().should.deep.equal ['photo1.jpg', 'photo3.jpg']

        it 'detach all related objects when empty list assigned', co ->
            [alice, _] = yield fixtures.alice()

            yield Photo.where('user_id', '=', alice.id).count().then(parseInt).should.become 2
            yield alice.$photos.assign []
            Photo.where('user_id', '=', alice.id).count().then(parseInt).should.become 0

