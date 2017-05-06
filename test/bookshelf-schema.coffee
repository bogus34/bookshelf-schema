Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
Fields = require '../src/fields'
Relations = require '../src/relations'

{StringField, IntField, EmailField} = Fields
{HasMany, BelongsTo} = Relations


describe "Bookshelf schema", ->
    this.timeout 3000
    db = null

    before ->
        db = init.init()

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

    it 'can extend from an extended model', ->
        BaseModel = db.Model.extend {
            constructor: ->
                db.Model.apply this, arguments
                this.base_property = true
        }, {
            schema: [
                StringField 'commonid'
            ]
        }

        User = BaseModel.extend {
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
        user = new User
        user.base_property.should.be.true

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
