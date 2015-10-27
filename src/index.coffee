###
#
#  User = db.Model.extend({
#      tableName: 'users'
#  }, {
#      schema: [
#          StringField 'username'
#          IntField 'age'
#          EmailField 'email'
#
#          HasMany 'photos', Photo, onDestroy: 'cascade'
#      ]
#  });
#
#  class User extends db.Model.extend
#      tableName: 'users'
#      @schema [
#          StringField 'username'
#          IntField 'age'
#          EmailField 'email'
#
#          HasMany 'photos', Photo, onDestroy: 'cascade'
#      ]
#
###

CheckIt = require 'checkit'
utils = require './utils'

plugin = (options = {}) -> (db) ->
    options.createProperties ?= true
    options.validation ?= true

    originalModel = db.Model

    buildSchema = (entities) ->
        schema = []
        e.contributeToSchema?(schema) for e in entities
        schema

    contributeToModel = (cls, entities) ->
        e.contributeToModel(cls) for e in entities
        undefined

    class Model extends db.Model
        @db: db
        @transaction: db.transaction.bind db
        @__bookshelf_schema_options = options

        @schema: (schema) ->
            @__schema = buildSchema schema
            contributeToModel this, @__schema

        @extend: (props, statics) ->
            if statics.schema
                schema = statics.schema
                delete statics.schema
            cls = originalModel.extend.call this, props, statics
            return cls unless schema
            cls.schema schema
            cls

        initialize: ->
            super
            @initSchema()

        initSchema: ->
            @constructor.__schema ?= []
            e.initialize?(this) for e in @constructor.__schema
            if @constructor.__bookshelf_schema_options.validation
                @on 'saving', @validate, this
            for e in @constructor.__schema when e.onDestroy?
                @on 'destroying', @_handleDestroy, this
                # _handleDestroy will iterate over all schema entities so we break here
                break
            if @constructor.__bookshelf_schema?.defaultScope
                @constructor.__bookshelf_schema.defaultScope.apply(this)
            undefined

        format: (attrs, options) ->
            attrs = super attrs, options
            if @constructor.__bookshelf_schema
                for f in @constructor.__bookshelf_schema.formatters
                    f attrs, options
            attrs

        parse: (resp, options) ->
            attrs = super resp, options
            if @constructor.__bookshelf_schema
                for f in @constructor.__bookshelf_schema.parsers
                    f attrs, options
            attrs

        validate: (self, attrs) ->
            return utils.Fulfilled() unless @constructor.__bookshelf_schema_options.validation
            json = @toJSON(validating: true)
            validations = @constructor.__bookshelf_schema?.validations || []
            modelValidations = @constructor.__bookshelf_schema?.modelValidations
            options = @_checkitOptions.call(this)
            checkit = CheckIt(validations, options).run(json)
            if @modelValidations and @modelValidations.length > 0
                checkit = checkit.then -> CheckIt(all: model_validations, options).run(all: json)
            checkit

        destroy: (options) ->
            utils.forceTransaction Model.transaction, options, (options) =>
                super options

        for method in ['all', 'fetch']
            do (method) ->
                Model::[method] = ->
                    @_applyScopes()
                    super

        for method in ['hasMany', 'hasOne', 'belongsToMany', 'morphOne', 'morphMany', 'belongsTo', 'through']
            do (method) ->
                Model::[method] = ->
                    related = super
                    @_liftRelatedScopes related
                    related.unscoped = @unscoped
                    related

        unscoped: ->
            @_appliedScopes = []
            this
        @unscoped: -> @forge().unscoped()

        _checkitOptions: ->
            memo = {}
            for k in ['language', 'labels', 'messages']
                if @constructor.__bookshelf_schema_options[k]
                    memo[k] = @constructor.__bookshelf_schema_options[k]
            memo

        _handleDestroy: (model, options = {}) ->
            # somehow query passed with options will break some of subsequent queries
            options = utils.clone options, expect: ['query']
            options.destroyingCache = "#{model.tableName}:#{model.id}": utils.Fulfilled()
            handled = (e.onDestroy?(model, options) for e in @constructor.__schema)
            Promise.all(handled)
            .then -> Promise.all utils.values(options.destroyingCache)
            .then -> delete options.destroyingCache

        _applyScopes: ->
            if @_appliedScopes
                @query (qb) => scope.apply(qb, args) for [name, scope, args] in @_appliedScopes

        _liftRelatedScopes: (to) ->
            target = to.model or to.relatedData.target
            if target and target.__schema?
                for e in target.__schema when e.liftScope?
                    e.liftScope(to)

    class Collection extends db.Collection
        for method in ['fetch', 'fetchOne']
            do (method) ->
                Collection::[method] = ->
                    @_applyScopes()
                    super

        _applyScopes: ->
            if @_appliedScopes
                @query (qb) => scope.apply(qb, args) for [name, scope, args] in @_appliedScopes

    db.Model = Model
    db.Collection = Collection

module.exports = plugin
