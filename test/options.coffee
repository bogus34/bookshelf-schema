Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
Options = require '../src/options'

describe "Bookshelf schema", ->
    this.timeout 3000
    db = null

    before ->
        db = init.init()

    describe 'Options', ->
        it 'applies options from schema', ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    Options validation: false
                ]

            User.__bookshelf_schema_options.validation.should.be.false
            db.Model.__bookshelf_schema_options.validation.should.be.true
