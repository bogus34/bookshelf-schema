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
    Inviter = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            photos = yield [
                new Photo(filename: 'photo1.jpg', user_id: alice.id).save()
                new Photo(filename: 'photo2.jpg', user_id: alice.id).save()
            ]
            [alice, photos]
        aliceBobAndCharley: co ->
            [alice, bob, charley] = yield [
                 new User(username: 'alice').save()
                 new User(username: 'bob').save()
                 new User(username: 'charley').save()
            ]
            [inviter1, inviter2] = yield [
                 new Inviter(greeting: 'Hello Bob!', user_id: alice.id).save()
                 yield new Inviter(greeting: 'Hi Charley!', user_id: alice.id).save()
            ]
            yield [ bob.save(inviter_id: inviter1.id), charley.save(inviter_id: inviter2.id) ]

            [alice, bob, charley]

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

        afterEach -> init.truncate 'users', 'photos'

        it 'create accessor', co ->
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

        it 'fixes count method', co ->
            [alice, photos] = yield fixtures.alice()
            otherPhoto = yield new Photo(filename: 'photo3.jpg').save()
            yield [
                alice.$photos.count().should.become photos.length
                alice.$photos._originalCount().should.not.become photos.length
            ]

    describe 'through', ->
        before -> init.inviters()

        beforeEach ->
            class Inviter extends db.Model
                tableName: 'inviters'

            class User extends db.Model
                tableName: 'users'

                @schema [
                    StringField 'username'
                    HasMany User, name: 'invited', through: Inviter
                ]

            Inviter.schema [
                StringField 'greeting'
            ]

        afterEach -> init.truncate 'users', 'inviters'

        it 'can access related model', co ->
            [alice, bob, charley] = yield fixtures.aliceBobAndCharley()
            yield alice.load('invited')
            alice.$invited.should.be.an.instanceof db.Collection
            alice.$invited.pluck('username').sort().should.deep.equal ['bob', 'charley']

