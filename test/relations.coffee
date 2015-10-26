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

        afterEach -> init.truncate 'users', 'photos'

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
