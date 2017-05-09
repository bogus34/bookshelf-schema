Bookshelf = require 'bookshelf'
Uuid = require 'node-uuid'
Schema = require '../src/'
init = require './init'
Fields = require '../src/fields'
Relations = require '../src/relations'

{StringField, IntField, EmailField, DateTimeField, UUIDField} = Fields
{HasMany, BelongsTo} = Relations

describe "Relations", ->
    this.timeout 3000
    db = null
    User = null
    Photo = null
    Post = null
    Link = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            photos = yield [
                new Photo(filename: 'photo1.jpg', user_id: alice.id).save()
                new Photo(filename: 'photo2.jpg', user_id: alice.id).save()
            ]
            post1 = yield new Post(posted_at: new Date, edited_at: new Date, body: "Frist Post", user_id: alice.id).save()
            [alice, photos, post1]
            post2 = yield new Post(posted_at: new Date, edited_at: new Date, body: "2nd psot", user_id: alice.id).save()
            link = yield new Link(url: 'http://localhost', post_id: post1.id).save()
            [alice, photos, post1, post2, link]

    before co ->
        db = init.init()
        yield [ init.users(), init.photos(), init.posts(), init.links() ]

    describe 'Common', ->
        beforeEach ->
            class Photo extends db.Model
                tableName: 'photos'

            class User extends db.Model
                tableName: 'users'

            Photo.schema [
                StringField 'filename'
                BelongsTo User
            ]

            class Link extends db.Model
                tableName: 'links'
                initialize: co ->
                    db.Model.initialize?.call this
                    def = this.defaults? || {}
                    def.id = Uuid.v4()
                    this.defaults = def

            class Post extends db.Model
                tableName: 'posts'
                initialize: (attributes, options) ->
                    db.Model.initialize?.call this
                    def = this.defaults? || {}
                    def.id = Uuid.v4()
                    this.defaults = def
                @schema [
                    DateTimeField 'posted_at'
                    DateTimeField 'edited_at'
                    StringField 'body'
                    BelongsTo User
                    HasMany Link
                ]

            User.schema [
                StringField 'username'
                HasMany Photo
                HasMany Post
            ]

            Link.schema [
                StringField 'url'
                UUIDField 'post_id'
                BelongsTo Post
            ]

        afterEach -> init.truncate 'users', 'photos', 'posts', 'links'

        it 'does something relevant', co ->
            [alice, photos, post1, post2, link] = yield fixtures.alice()
            yield alice.load('photos')

            alice.$photos.at(0).should.be.an.instanceof Photo

        it 'uses passed query processor', co ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    HasMany Photo, query: -> @query('where', 'filename', '=', 'photo1.jpg')
                ]

            [alice, photos, post1, post2, link] = yield fixtures.alice()

            yield alice.$photos.count().should.become 1
            photos = yield alice.$photos.fetch()
            photos.length.should.be.equal 1
            photos.first().should.be.an.instanceof Photo
            photos.first().filename.should.be.equal 'photo1.jpg'

        it 'can relate models by uuid', co ->
            [alice, _] = yield fixtures.alice()
            yield alice.load('posts')
            post = alice.$posts.first()
            post.should.be.an.instanceof Post
            yield post.load('links')
            link = post.$links.first()
            link.post_id.should.equal(post.id)

        it 'works with plugin registry', co ->
            db2 = Bookshelf db.knex
            db2.plugin 'registry'

            db2.plugin Schema()

            class User extends db2.Model
                tableName: 'users'
                @schema [
                    HasMany 'Photo'
                ]
            db2.model 'User', User

            class Photo extends db2.Model
                tableName: 'photos'
                @schema [
                    StringField 'filename'
                ]
            db2.model 'Photo', Photo

            [alice, photos, post1, post2, link] = yield fixtures.alice()

            alice.$photos.count().should.become 2

    describe 'Configurable accessor prefix', ->
        it 'can use different accessor prefix for relations', co ->
            class Photo extends db.Model
                tableName: 'photos'

            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username'
                    HasMany Photo, accessorPrefix: 'rel_'
                ]

            Photo.schema [
                StringField 'filename'
                BelongsTo User
            ]

            [alice, photos, post1, post2, link] = yield fixtures.alice()
            yield alice.load('photos')

            photo = alice.rel_photos.at(0)

            photo.should.be.an.instanceof Photo
            expect(alice.$photos).not.to.be.defined

            yield photo.load('user')
            photo.$user.should.be.an.instanceof User

        it 'allows pluginwide configure of relations accessor prefix', co ->
            db2 = Bookshelf db.knex
            db2.plugin 'registry'

            db2.plugin Schema(relationsAccessorPrefix: 'rel_')

            class Photo extends db.Model
                tableName: 'photos'

            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username'
                    HasMany Photo, accessorPrefix: 'rel_'
                ]

            [alice, photos, post1, post2, link] = yield fixtures.alice()
            yield alice.load('photos')

            alice.rel_photos.at(0).should.be.an.instanceof Photo
