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

    #
    # Bookshelf.Model.extend manipulates __proto__ instead of copying static
    # methods to child class and it breaks normal CoffeeScript inheritance.
    # So if any plugin added before Schema extends Model, we have a problem.
    # This function is trying to fix it.
    #
    fixInheritance = (base, cls) ->
        proto = base.__proto__
        while typeof proto is 'function'
            for own k, v of proto when not cls.hasOwnProperty(k)
                cls[k] = v
            proto = proto.__proto__

    buildSchema = (entities) ->
        schema = []
        e.contributeToSchema?(schema) for e in entities
        schema

    contributeToModel = (cls, entities) ->
        e.contributeToModel(cls) for e in entities
        undefined

    applyAliases = (aliases, attrs) ->
        attrs = utils.clone attrs
        for name, column of aliases
            if attrs[name] and not attrs[column]
                attrs[column] = attrs[name]
                delete attrs[name]
        attrs

    class Model extends db.Model
        @db: db
        @transaction: db.transaction.bind db
        @__bookshelf_schema_options = options

        @schema: (schema) ->
            @__schema = buildSchema schema
            contributeToModel this, @__schema

        @extend: (props, statics) ->
            if statics?.schema
                schema = statics.schema
                delete statics.schema

            #
            # As with fixInheritance but for the case when someone extends Model after Schema
            # We copy static properties over to fix CoffeeScript class inheritance after it.
            #
            ctor = if props.hasOwnProperty 'constructor'
                props.constructor
            else
                -> Model.apply(this, arguments)
            ctor[k] = v for own k, v of Model
            props.constructor = ctor

            cls = super props, statics

            return cls unless schema
            cls.schema schema
            cls

        constructor: (attributes, options) ->
            @constructor.__schema ?= []
            return super unless attributes

            if @constructor.__bookshelf_schema?.aliases
                attributes = applyAliases @constructor.__bookshelf_schema.aliases, attributes

            super attributes, options

        initialize: ->
            super
            @initSchema()

        initSchema: ->
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
            if @constructor.__bookshelf_schema?.parsers
                for f in @constructor.__bookshelf_schema.parsers
                    f attrs, options
            attrs

        toJSON: (options = {}) ->
            json = super

            if not options.validating and
            not options.use_columns and
            @constructor.__bookshelf_schema.aliases
                aliases = @constructor.__bookshelf_schema.aliases
                json = applyAliases utils.invert(aliases), json

            json

        validate: (self, attrs, options = {}) ->
            if not @constructor.__bookshelf_schema_options.validation \
            or options.validation is false
                return utils.Fulfilled()
            json = @toJSON(validating: true)
            validations = @constructor.__bookshelf_schema?.validations or []
            modelValidations = @constructor.__bookshelf_schema?.modelValidations
            options = @_checkitOptions.call(this)
            checkit = CheckIt(validations, options).run(json)
            if @modelValidations and @modelValidations.length > 0
                checkit = checkit.then -> CheckIt(all: model_validations, options).run(all: json)
            checkit

        save: (key, value, options) ->
            return super unless @constructor.__bookshelf_schema?.aliases

            if not key? or typeof key is 'object'
                attrs = if key? then utils.clone(key) else {}
                options = utils.clone(value) or {}
            else
                attrs = { "#{key}": value }
                options = utils.clone(options) or {}

            attrs = applyAliases @constructor.__bookshelf_schema.aliases, attrs

            super attrs, options

        destroy: (options) ->
            utils.forceTransaction Model.transaction, options, (options) =>
                super options

        for method in ['all', 'fetch']
            do (method) ->
                Model::[method] = ->
                    @_applyScopes()
                    super

        for method in ['hasMany', 'hasOne', 'belongsToMany',
        'morphOne', 'morphMany', 'belongsTo', 'through']
            do (method) ->
                Model::[method] = ->
                    related = super
                    @_liftRelatedScopes related
                    related.unscoped = -> @clone()
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
            options = utils.clone options, except: ['query']
            options.destroyingCache = "#{model.tableName}:#{model.id}": utils.Fulfilled()
            handled = (e.onDestroy?(model, options) for e in @constructor.__schema)
            Promise.all(handled)
            .then -> Promise.all utils.values(options.destroyingCache)
            .then -> delete options.destroyingCache

        _applyScopes: ->
            if @_appliedScopes
                for [name, scope, args] in @_appliedScopes
                    @query (qb) -> scope.apply(qb, args)
                delete @_appliedScopes

        _liftRelatedScopes: (to) ->
            target = to.model or to.relatedData.target
            if target and target.__schema?
                for e in target.__schema when e.liftScope?
                    e.liftScope(to)

    fixInheritance db.Model, Model

    class Collection extends db.Collection
        for method in ['fetch', 'fetchOne']
            do (method) ->
                Collection::[method] = ->
                    @_applyScopes()
                    super

        count: (column = '*', options) ->
            @_applyScopes?()
            sync = @sync(options)
            query = sync.query.clone()
            @_knex = sync.query

            relatedData = sync.syncing.relatedData
            if relatedData
                if relatedData.isJoined()
                    relatedData.joinClauses query
                relatedData.whereClauses query

            query.count(column)
            .then (result) ->
                Number utils.values(result[0])[0]

        cloneWithScopes: ->
            result = @clone()
            if @_liftedScopes
                for scope in @_liftedScopes
                    scope.liftScope(result)
            result._appliedScopes = @_appliedScopes[..] if @_appliedScopes
            result

        _applyScopes: Model::_applyScopes

    fixInheritance db.Collection, Collection

    db.Model = Model
    db.Collection = Collection

module.exports = plugin
