Bookshelf = require 'bookshelf'
Schema = require '../../src/'
init = require '../init'
Fields = require '../../src/fields'
Relations = require '../../src/relations'

{StringField, IntField, EmailField} = Fields
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
        aliceAndBob: co ->
            [alice, bob] = yield [
                 new User(username: 'alice').save()
                 new User(username: 'bob').save()
            ]
            inviter = yield new Inviter(greeting: 'Hello Bob!', user_id: alice.id).save()
            yield bob.save(inviter_id: inviter.id)
            [alice, bob, inviter]

    before co ->
        db = init.init()
        yield [ init.users(), init.photos() ]

    describe 'BelongsTo', ->
        describe 'plain', ->
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

            it 'creates accessor', co ->
                [alice, [photo1, _]] = yield fixtures.alice()
                photo1.user.should.be.a 'function'
                yield photo1.load 'user'
                photo1.$user.should.be.an.instanceof User
                photo1.$user.username.should.equal alice.username

            it 'can assign model', co ->
                [alice, [photo1, _]] = yield fixtures.alice()

                bob = yield new User(username: 'bob').save()
                yield photo1.$user.assign bob
                photo1 = yield Photo.forge(id: photo1.id).fetch(withRelated: 'user')
                photo1.user_id.should.equal bob.id
                photo1.$user.id.should.equal bob.id

            it 'can assign plain object', co ->
                [alice, [photo1, _]] = yield fixtures.alice()

                yield photo1.$user.assign {username: 'bob'}
                photo1 = yield Photo.forge(id: photo1.id).fetch(withRelated: 'user')
                photo1.$user.username.should.equal 'bob'

            it 'can assign by id', co ->
                [alice, [photo1, _]] = yield fixtures.alice()

                bob = yield new User(username: 'bob').save()
                yield photo1.$user.assign bob.id
                photo1 = yield Photo.forge(id: photo1.id).fetch(withRelated: 'user')
                photo1.user_id.should.equal bob.id
                photo1.$user.id.should.equal bob.id

            it 'can assign null as a related object', co ->
                [alice, [photo1, _]] = yield fixtures.alice()

                yield photo1.$user.assign(null)
                photo1 = yield Photo.forge(id: photo1.id).fetch()
                expect(photo1.user_id).to.be.null

            it 'can use custom foreign key and foreign key target', co ->
                class OtherPhoto extends db.Model
                    tableName: 'photos'
                    @schema [
                        StringField 'filename'
                        StringField 'user_name'
                        BelongsTo User, foreignKey: 'user_name', foreignKeyTarget: 'username'
                    ]

                [alice, [photo1, _]] = yield fixtures.alice()
                photo2 = yield OtherPhoto.forge(id: photo1.id).fetch()
                photo2.user_name = alice.username
                yield photo2.save()
                yield photo2.load('user')
                photo2.$user.id.should.equal alice.id

        describe 'through', ->
            before -> init.inviters()

            beforeEach ->
                class Inviter extends db.Model
                    tableName: 'inviters'

                class User extends db.Model
                    tableName: 'users'

                    @schema [
                        StringField 'username'
                        BelongsTo User, name: 'inviter', through: Inviter
                    ]

                Inviter.schema [
                    StringField 'greeting'
                ]

            afterEach -> init.truncate 'users', 'inviters'

            it 'can access related model', co ->
                [alice, bob, inviter] = yield fixtures.aliceAndBob()
                yield bob.load('inviter')
                bob.$inviter.should.be.an.instanceof User
                bob.$inviter.id.should.equal alice.id

        describe 'onDestroy', ->
            beforeEach ->
                class Photo extends db.Model
                    tableName: 'photos'

                class User extends db.Model
                    tableName: 'users'

            afterEach -> init.truncate 'users', 'photos'

            it 'can cascade-destroy dependent models', co ->
                Photo.schema [
                    BelongsTo User, onDestroy: 'cascade'
                ]

                [alice, [photo1, photo2]] = yield fixtures.alice()
                yield photo1.destroy().should.be.fulfilled
                [alice, photo2] = yield [
                    new User(id: alice.id).fetch()
                    new Photo(id: photo2.id).fetch()
                ]

                expect(alice).to.be.null
                expect(photo2).not.to.be.null

            it 'can reject destroy when there is dependent model', co ->
                Photo.schema [
                    BelongsTo User, onDestroy: 'reject'
                ]

                [alice, [photo1, _]] = yield fixtures.alice()
                yield photo1.destroy().should.be.rejected
                yield photo1.$user.assign null
                photo1.destroy().should.be.fulfilled

            it 'can detach dependend models on destroy', co ->
                Photo.schema [
                    # this actually a no-op
                    BelongsTo User, onDestroy: 'detach'
                ]

                [alice, [photo1, _]] = yield fixtures.alice()
                yield photo1.destroy().should.be.fulfilled

        describe 'tries to assign correct name to foreign key field', ->
            beforeEach ->
                class User extends db.Model
                    tableName: 'users'

                class Photo extends db.Model
                    tableName: 'photos'

            it 'uses <modelName>_id by default', ->
                Photo.schema [
                    BelongsTo User
                ]

                Photo.prototype.hasOwnProperty('user_id').should.be.true

            it 'uses foreign key if defined', ->
                Photo.schema [
                    BelongsTo User, foreignKey: 'userId'
                ]

                Photo.prototype.hasOwnProperty('userId').should.be.true
