Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
Fields = require '../src/fields'
Relations = require '../src/relations'

{HasMany} = Relations

describe "Issues", ->
    this.timeout 3000
    db = null

    before co ->
        db = init.init()
        db.plugin 'registry'

    describe "#3", ->
        JournalItemsModel = JournalModel = null

        createTables = co ->
            knex = db.knex
            yield knex.schema.dropTableIfExists 'journal'
            yield knex.schema.createTable 'journal', (table) ->
                table.increments('id').primary()

            yield knex.schema.dropTableIfExists 'journal_items'
            yield knex.schema.createTable 'journal_items', (table) ->
                table.increments('id').primary()
                table.integer 'journal_id'

        before co ->
            yield createTables()

            JournalItemsModel = db.Model.extend {
                tableName: 'journal_items'
            }, {}
            db.model 'JournalItem', JournalItemsModel

            JournalModel = db.Model.extend {
                tableName: 'journal'
            }, {}
            db.model 'Journal', JournalModel

        it 'should deduce relation name more properly', ->
            # It should not throw
            JournalModel.schema [
                HasMany JournalItemsModel
            ]

        it 'should allow to use camelcase name for relations', co ->
            JournalModel.schema [
                HasMany JournalItemsModel, name: 'JournalItems'
            ]

            journal = yield JournalModel.forge().save()

            yield JournalModel.forge(id: journal.id).fetch(withRelated: ['JournalItems'])
