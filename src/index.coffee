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
    options.validation ?= true

    Model = db.Model
    Model.__bookshelf_schema_options = options
    Model.schema = applySchema
    Model::validate = validate

    replaceExtend Model

applySchema = (schema) ->
    @__schema = buildSchema schema
    contributeToModel this, @__schema

    oldInitialize = @::initialize
    @::initialize = ->
        if oldInitialize?
            oldInitialize.apply this, arguments
        initSchema.apply this

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
    if @constructor.__bookshelf_schema_options.validation
        @on 'saving', @validate, this
    undefined

Fulfilled = -> new Promise (resolve, reject) -> resolve()
Rejected = -> new Promise (resolve, reject) -> reject()

validate = (self, attrs) ->
    return Fulfilled() unless @constructor.__bookshelf_schema_options.validation
    json = @toJSON(validating: true)
    validations = @constructor.__bookshelf_schema.validations
    modelValidations = @constructor.__bookshelf_schema.modelValidations
    checkit = CheckIt(validations).run(json)
    if @modelValidations and @modelValidations.length > 0
        checkit = checkit.then -> CheckIt(all: model_validations).run(all: json)
    checkit

module.exports = plugin
