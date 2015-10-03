CheckIt = require 'checkit'

###
#
# User = db.Model.extend({
#     tableName: 'users'
# }, {
#     schema: [
#         StringField 'username'
#         IntField 'age'
#         EmailField 'email'
#
#         HasMany 'photos', Photo, onDelete: 'cascade'
#     ]
# });
#
# class User extends db.Model.extend
#     tableName: 'users'
#     @schema [
#         StringField 'username'
#         IntField 'age'
#         EmailField 'email'
#
#         HasMany 'photos', Photo, onDelete: 'cascade'
#     ]
#
###

plugin = (options = {}) -> (db) ->
    options.createProperties ?= true

    Model = db.Model
    Model.schema = applySchema

    replaceExtend Model

applySchema = (schema) ->
    @__schema = buildSchema schema
    contributeToModel this, schema

    oldInitialize = @::initialize
    @::initialize = ->
        oldInitialize?()
        initSchema()

replaceExtend = (Model) ->
    originalExtend = Model.extend
    Model.extend = (props, statics) ->
        if statics.schema
            schema = statics.schema
            delete statics.schema
        cls = originalExtend.call Model, props, statics
        return cls unless schema
        applySchema.call cls, schema
        cls

buildSchema = (entities) ->
    schema = []
    e.contributeToSchema?(schema) for e in entities
    schema

contributeToModel = (cls, entities) ->
    e.contributeToModel(cls) for e in entities
    undefined

initSchema = ->
    e.initialize?(this) for e in @constructor.__schema
    undefined

module.exports = plugin
