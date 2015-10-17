Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
Fields = require '../src/fields'
Relations = require '../src/relations'

{StringField, IntField, EmailField} = Fields
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

    describe 'Common', ->
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

        it 'does something relevant', co ->
            [alice, _] = yield fixtures.alice()
            yield alice.load('photos')

            alice.$photos.at(0).should.be.an.instanceof Photo

        it 'uses passed query processor', co ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    HasMany Photo, query: -> @query('where', 'filename', '=', 'photo1.jpg')
                ]

            [alice, _] = yield fixtures.alice()

            photos = yield alice.$photos.fetch()
            photos.length.should.be.equal 1
            photos.first().should.be.an.instanceof Photo
            photos.first().filename.should.be.equal 'photo1.jpg'

    describe 'BelongsTo', ->
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
            [alice, photos] = yield fixtures.alice()
            photo1 = photos[0]
            yield photo1.load 'user'
            photo1.$user.should.be.an.instanceof User
            photo1.$user.username.should.equal alice.username

        it 'can assign related object', co ->
            [alice, photos] = yield fixtures.alice()

            bob = yield new User(username: 'bob').save()
            photo1 = photos[0]
            yield photo1.$user.assign(bob)
            photo1 = yield Photo.forge(id: photo1.id).fetch()
            photo1.user_id.should.equal bob.id
            user = yield photo1.$user.fetch()
            user.id.should.equal bob.id

        it 'can assign null as a related object', co ->
            [alice, photos] = yield fixtures.alice()
            photo1 = photos[0]

            yield photo1.$user.assign(null)
            photo1 = yield Photo.forge(id: photo1.id).fetch()
            expect(photo1.user_id).to.be.null
