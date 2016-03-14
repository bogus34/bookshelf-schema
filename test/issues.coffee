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

    it '#3 - should deduce relation name more properly', ->
        # It should not throw

        JournalItemsModel = db.Model.extend {
            tableName: 'journal_items'
        }, {}
        db.model 'JournalItem', JournalItemsModel

        JournalModel = db.Model.extend {
            tableName: 'journal'
        }, {
            schema: [
                HasMany JournalItemsModel
            ]
        }
        db.model 'Journal', JournalModel
