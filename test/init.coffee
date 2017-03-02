Knex = require 'knex'
Bookshelf = require 'bookshelf'
Schema = require '../src/'

db = null

initDb = ->
    db_variant = process.env.BOOKSHELF_SCHEMA_TESTS_DB_VARIANT
    db_variant ?= 'sqlite'

    knex = switch db_variant
        when 'sqlite'
            Knex
                client: 'sqlite'
                debug: process.env.BOOKSHELF_SCHEMA_TESTS_DEBUG?
                connection:
                    filename: ':memory:'
                useNullAsDefault: true
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
                useNullAsDefault: true
        else throw new Error "Unknown db variant: #{db_variant}"

    db = Bookshelf knex

init = (pluginOptions) ->
    return db if db?
    db = initDb()
    db.plugin Schema(pluginOptions)
    db

truncate = co (tables...) -> yield (db.knex(table).truncate() for table in tables)

users = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists 'users'
    yield knex.schema.createTable 'users', (table) ->
        table.increments('id').primary()
        table.string 'username', 255
        table.string 'password', 1024
        table.string 'email', 255
        table.float 'code'
        table.boolean 'flag'
        table.dateTime 'last_login'
        table.date 'birth_date'
        table.json 'additional_data'
        table.integer 'inviter_id'

photos = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists 'photos'
    yield knex.schema.createTable 'photos', (table) ->
        table.increments('id').primary()
        table.string 'filename', 255
        table.integer 'user_id'
        table.string 'user_name', 255

profiles = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists 'profiles'
    yield knex.schema.createTable 'profiles', (table) ->
        table.increments('id').primary()
        table.string 'greetings', 255
        table.integer 'user_id'

groups = co ->
    init() unless db
    knex = db.knex
    yield [
        knex.schema.dropTableIfExists 'groups'
        knex.schema.dropTableIfExists 'groups_users'
    ]
    yield knex.schema.createTable 'groups', (table) ->
        table.increments('id').primary()
        table.string 'name', 255
    yield knex.schema.createTable 'groups_users', (table) ->
        table.integer 'user_id'
        table.integer 'group_id'

tags = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists 'tags'
    yield knex.schema.createTable 'tags', (table) ->
        table.increments('id').primary()
        table.string 'name', 255
        table.integer 'tagable_id'
        table.string 'tagable_type', 255

inviters = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists 'inviters'
    yield knex.schema.createTable 'inviters', (table) ->
        table.increments('id').primary()
        table.string 'greeting'
        table.integer 'user_id'

module.exports =
    initDb: initDb
    init: init
    truncate: truncate
    users: users
    photos: photos
    profiles: profiles
    groups: groups
    tags: tags
    inviters: inviters
