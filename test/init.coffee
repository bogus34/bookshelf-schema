Knex = require 'knex'
Bookshelf = require 'bookshelf'
Schema = require '../src/'

db = null
init = ->
    return db if db?

    db_variant = process.env.BOOKSHELF_SCHEMA_TESTS_DB_VARIANT
    db_variant ?= 'sqlite'

    knex = switch db_variant
        when 'sqlite'
            Knex
                client: 'sqlite'
                debug: process.env.BOOKSHELF_SCHEMA_TESTS_DEBUG?
                connection:
                    filename: ':memory:'
        when 'pg', 'postgres'
            Knex
                client: 'pg'
                debug: process.env.BOOKSHELF_SCHEMA_TESTS_DEBUG?
                connection:
                    host: '127.0.0.1'
                    user: 'test'
                    password: 'test'
                    database: 'test'
                    charset: 'utf8'
        else throw new Error "Unknown db variant: #{db_variant}"

    db = Bookshelf knex
    db.plugin Schema()
    db

users = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists('users')
    yield knex.schema.createTable 'users', (table) ->
        table.increments('id').primary()
        table.string 'username', 255
        table.string 'email', 255
        table.float 'code'
        table.boolean 'flag'
        table.dateTime 'last_login'
        table.date 'birth_date'
        table.json 'additional_data'

photos = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists('photos')
    yield knex.schema.createTable 'photos', (table) ->
        table.increments('id').primary()
        table.string 'filename', 255
        table.integer 'user_id'

module.exports =
    init: init
    users: users
    photos: photos
