Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
Fields = require '../src/fields'
Relations = require '../src/relations'

{StringField, IntField, EmailField, DateField} = Fields
{HasMany, BelongsTo} = Relations


describe "Bookshelf schema", ->
    this.timeout 3000
    db = null
    User = null
    Photo = null
    example_email = 'foo@bar.com'

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice', birth_date: new Date, email: example_email).save()
            photos = yield [
                new Photo(filename: 'photo1.jpg', user_id: alice.id).save()
                new Photo(filename: 'photo2.jpg', user_id: alice.id).save()
            ]

    before co ->
        db = init.init()
        yield [ init.users(), init.photos() ]

    it 'can apply schema with Model.extend', ->
        User = db.Model.extend {
            tableName: 'users'
        }, {
            schema: [
                StringField 'username'
                IntField 'age'
                EmailField 'email'
            ]
        }

        User.__bookshelf_schema.should.be.defined
        User.prototype.hasOwnProperty('username').should.be.true
        User.prototype.hasOwnProperty('age').should.be.true
        User.prototype.hasOwnProperty('email').should.be.true

    it 'can extend from an extended model', co ->
        BaseModel = db.Model.extend {
            constructor: ->
                db.Model.apply this, arguments
                this.base_property = true
        }, {
            schema: [
                StringField 'commonid'
            ]
        }

        Serializer = {
            serialize: ->
                serialized = db.Model.prototype.serialize.apply this, arguments
                if 'password' of serialized
                    delete serialized['password']
                serialized
        }

        User = BaseModel.extend
            tableName: 'users'

        Photo = BaseModel.extend
            tableName: 'photos'

        User.schema [
            StringField 'username'
            StringField 'password'
            DateField 'birth_date'
            EmailField 'email'
            HasMany Photo
        ]

        Photo.schema [
            StringField 'filename'
            StringField 'user_name'
            BelongsTo User
        ]

        User = User.extend Serializer
        Photo = Photo.extend Serializer

        [alice, photos] = yield fixtures.alice()

        User.__bookshelf_schema.should.be.defined
        User.__schema.should.be.defined

        alice = yield User.forge(id: alice.id).fetch(withRelated: 'photos')
        alice.username.should.equal 'alice'
        alice.email.should.equal example_email
        photo0 = alice.$photos.at(0)
        photo0.filename.should.equal 'photo1.jpg'

        bob = yield new User(username: 'bob', password: 's3kr37', birth_date: new Date, email: example_email).save()
        bob = yield User.forge(id: bob.id).fetch()
        bob.username.should.equal 'bob'
        bob.email.should.equal example_email
        pickledbob = bob.serialize()
        pickledbob.should.not.have.key 'password'

    it 'can apply schema with coffeescript @schema static method', ->
        class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username'
                IntField 'age'
                EmailField 'email'
            ]

        User.__bookshelf_schema.should.be.defined
        User.prototype.hasOwnProperty('username').should.be.true
        User.prototype.hasOwnProperty('age').should.be.true
        User.prototype.hasOwnProperty('email').should.be.true

    it "doesn't add property if field has option createProperty: false", ->
        class User extends db.Model
            tableName: 'users'
            @schema [
                StringField 'username', createProperty: false
            ]

        User.prototype.hasOwnProperty('username').should.be.false

    it "doesn't add properties if initialized with option createProperties: false", ->
        db2 = Bookshelf db.knex
        db2.plugin Schema(createProperties: false)

        class User extends db2.Model
            tableName: 'users'
            @schema [
                StringField 'username'
            ]

        User.prototype.hasOwnProperty('username').should.be.false

    it "doesn't overwrite existing methods and properties", ->
        class User extends db.Model
            tableName: 'users'
            @schema [ StringField 'query' ]

        new User().query.should.be.a 'function'

    it 'field named "id" doesnt overwrite internal id property', ->
        class User extends db.Model
            tableName: 'users'
            @schema [ StringField 'id' ]

        new User(id: 1).id.should.equal 1

    it 'creates accessors for relations', ->
        class Photo extends db.Model

        class User extends db.Model
            tableName: 'users'
            @schema [
                HasMany Photo
            ]

        Photo.schema [
            BelongsTo User
        ]

        User.prototype.hasOwnProperty('$photos').should.be.true
        User.prototype.photos.should.be.a.function
