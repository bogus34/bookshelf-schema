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
    Model.schema = ->
    replaceExtend Model

replaceExtend = (Model) ->
    originalExtend = Model.extend
    Model.extend = (props, statics) ->
        cls = originalExtend.call Model, props, statics
        return cls unless cls.schema

        cls.schema = buildSchema cls.schema
        contributeToModel cls, cls.schema

        oldInitialize = cls::initialize
        cls::initialize = ->
            oldInitialize?()
            #applySchema()

        cls

buildSchema = (entities) ->
    schema = []
    e.contributeToSchema?(schema) for e in entities
    schema

contributeToModel = (cls, entities) ->
    e.contributeToModel(cls) for e in entities
    undefined

applySchema = ->
    e.initialize?(this) for e in @constructor.schema
    undefined

module.exports = plugin
