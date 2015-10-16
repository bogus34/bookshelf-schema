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

    before co ->
        db = init.init()
        yield [ init.users(), init.photos() ]

    afterEach co ->
        yield [ db.knex('users').truncate(), db.knex('photos').truncate() ]

    it 'does something relevant', co ->
        class Photo extends db.Model
            tableName: 'photos'

        class User extends db.Model
            tableName: 'users'
            @schema [
                HasMany Photo
            ]

        Photo.schema [
            BelongsTo User
        ]

        alice = yield new User(username: 'alice').save()
        yield [
            new Photo(filename: 'photo1.jpg', user_id: alice.id).save()
            new Photo(filename: 'photo2.jpg', user_id: alice.id).save()
        ]

        yield alice.load('photos')

        alice.$photos.at(0).should.be.an.instanceof Photo
