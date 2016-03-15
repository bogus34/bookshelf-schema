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
            expect( ->
                JournalModel.schema [
                    HasMany JournalItemsModel
                ]
            ).not.to.throw()

        it 'should allow to use camelcase name for relations', ->
            JournalModel.schema [
                HasMany JournalItemsModel, name: 'JournalItems'
            ]

            journal = yield JournalModel.forge().save()

            JournalModel.forge(id: journal.id).fetch(withRelated: ['JournalItems']).should.be.fullfiled

    describe '#4', ->
        describe 'should work with plugins that extends Model', co ->
            it 'added after Schema', ->
                db.plugin 'virtuals'
                db.plugin 'visibility'

                yield init.users()

                class User extends db.Model
                    tableName: 'users'

                    schema: [
                        Fields.StringField 'username'
                    ]

                User.forge(id: 1).fetch().should.be.fullfiled

            it 'added before Schema', co ->
                db = init.initDb()
                db.plugin 'virtuals'
                db.plugin 'visibility'
                db.plugin Schema()

                yield init.users()

                class User extends db.Model
                    tableName: 'users'

                    schema: [
                        Fields.StringField 'username'
                    ]

                User.forge(id: 1).fetch().should.be.fullfiled

            it 'added around Schema', co ->
                db = init.initDb()
                db.plugin 'virtuals'
                db.plugin Schema()
                db.plugin 'visibility'

                yield init.users()

                class User extends db.Model
                    tableName: 'users'

                    schema: [
                        Fields.StringField 'username'
                    ]

                User.forge(id: 1).fetch().should.be.fullfiled
