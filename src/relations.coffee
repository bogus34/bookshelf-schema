###
#
# BelongsTo 'user', User
#     leads to
#     user: -> @belongsTo User
#
# BelongsTo User
#     leads to
#     <User.name.toLowerCase()>: -> @belongsTo User
#
# BelongsTo 'user', User, -> @where(username: 'foo')
#     leads to
#     user: -> relation = @belongsTo(User); f.call(relation)
#
# class User extends db.Model
#     tableName: 'users'
#     @schema [
#         HasMany Photo
#     ]
#
# class Photo extends db.Model
#     tableName: 'photos'
#     @schema [
#         BelongsTo User
#     ]
#
# Photo.forge(id: 1).fetch(withRelated: 'user').then (photo) ->
#     photo.user                              # function
#     photo.related('user')                   # Model
#     photo.$user                             # Collection
#     photo.$user = user                      # set user_id to user.id
#     photo.$user.assign(user)                # set user_id to user.id and save
#
# User.forge(id: 1).fetch(withRelated: 'photos').then (user) ->
#     user.photos                             # function
#     user.related('photos')                  # Collection
#     user.$photos                            # Collection
#     user.$photos = [...]                    # detach all photos and attach listed
#     user.$photos.assign(...)                # detach all photos and attach listed
#     user.$photos.attach(...)                # attach listed photos and save them
#     user.$photos.detach(...)                # detach listed photos
#
# class User extends db.Model
#     tableName: 'users'
#     @schema [
#         HasMany Photo, onDestroy: (cascade|cascade direct|detach|detach direct|reject|ignore)
#     ]
#
###

###
#
# HasOne, BelongsTo, HasMany, BelongsToMany,
# MorphOne, MorphMany, MorphTo
#
###

pluralize = require 'pluralize'
{IntField} = require './fields'
{Fulfilled} = require './utils'

pluck = (obj, fields...) ->
    return {} unless obj?
    result = {}
    for f in fields when f of obj
        result[f] = obj[f]
    result

class Relation
    @multiple: false

    constructor: (model, options = {}) ->
        return new Relation(arguments...) unless this instanceof Relation
        @relatedModel = model
        @options = options
        @name = @options.name || @_deduceName(@relatedModel)

    pluginOption: (name, defaultVal) -> @model.__bookshelf_schema_options[name] or defaultVal
    contributeToSchema: (schema) -> schema.push this
    contributeToModel: (cls) ->
        @model = cls
        @accessor = @options.accessor || @_deduceAccessorName(@name)
        cls::[@name] = @createRelation(cls) unless @name of cls.prototype
        if (@options.createProperty or !@options.createProperty?) and @pluginOption('createProperties')
            @_createProperty(cls)

    createRelation: (cls) ->
        relation = if @options.query
            builder = @_createRelation(cls)
            query = @options.query
            -> query.apply builder.call(this)
        else
            @_createRelation(cls)

        self = this
        -> self._augementRelated this, relation.apply(this, arguments)

    resolveRelatedModel: ->
        @relatedModel

    createGetter: ->
        self = this
        -> @related(self.name)

    createSetter: ->

    _augementRelated: (parent, related) ->
        return related unless @constructor.helperMethods
        self = this
        for name, method of @constructor.helperMethods when name not of related
            related[name] = (args...) ->
                args.unshift self
                method.apply parent, args
        related

    _createProperty: (cls) ->
        return if @name is 'id' or @accessor of cls.prototype
        spec = {}
        getter = @createGetter()
        setter = @createSetter()
        spec.get = getter if getter
        spec.set = setter if setter

        Object.defineProperty cls.prototype, @accessor, spec

    _deduceName: ->
        if @constructor.multiple
            pluralize @relatedModel.name.toLowerCase()
        else
            @relatedModel.name.toLowerCase()

    _deduceAccessorName: -> "#{@pluginOption('relationAccessorPrefix', '$')}#{@name}"

class HasOne extends Relation
    constructor: (model, options = {}) ->
        return new HasOne(arguments...) unless this instanceof HasOne
        super

    _createRelation: (cls) ->
        related = @relatedModel
        foreignKey = @options.foreignKey
        -> @hasOne related, foreignKey

class BelongsTo extends Relation
    constructor: (model, options = {}) ->
        return new BelongsTo(arguments...) unless this instanceof BelongsTo
        super

    contributeToSchema: (schema) ->
        super
        schema.push IntField "#{@name}_id"

    @helperMethods:
        assign: (relation, obj, options) ->
            options = pluck options, 'transacting'
            foreignKey = relation.foreignKey()

            related = if obj is null
                Fulfilled {id: null}
            else if obj.constructor is Object
                @resolveRelatedModel().forge(obj).save(options)
            else
                Fulfilled obj

            related.then (related) =>
                options.patch = true
                @save(foreignKey, related.id, options)

    foreignKey: -> @options.foreignKey or "#{@name}_id"

    _createRelation: (cls) ->
        related = @relatedModel
        foreignKey = @options.foreignKey
        -> @belongsTo related, foreignKey

class HasMany extends Relation
    @multiple: true

    constructor: (model, options = {}) ->
        return new HasMany(arguments...) unless this instanceof HasMany
        super

    _createRelation: (cls) ->
        related = @relatedModel
        foreignKey = @options.foreignKey
        -> @hasMany related, foreignKey

class BelongsToMany extends Relation
    @multiple: true

    constructor: (model, options = {}) ->
        return new BelongsToMany(arguments...) unless this instanceof BelongsToMany
        super

    _createRelation: (cls) ->
        related = @relatedModel
        table = @options.table
        foreignKey = @options.foreignKey
        otherKey = @options.otherKey
        -> @belongsToMany related, table, foreignKey, otherKey

class MorphOne extends Relation
    constructor: (model, options = {}) ->
        return new MorphOne(arguments...) unless this instanceof MorphOne
        super

    _createRelation: (cls) ->
        related = @relatedModel
        name = @options.name
        columnNames = @options.columnNames
        morphValue = @options.morphValue
        -> @morphOne related, name, columnNames, morphValue

class MorphMany extends Relation
    @multiple: true

    constructor: (model, options = {}) ->
        return new MorphMany(arguments...) unless this instanceof MorphMany
        super

    _createRelation: (cls) ->
        related = @relatedModel
        name = @options.name
        columnNames = @options.columnNames
        morphValue = @options.morphValue
        -> @morphMany related, name, columnNames, morphValue

class MorphTo extends Relation
    constructor: (model, options = {}) ->
        return new MorphTo(arguments...) unless this instanceof MorphTo
        super

    _createRelation: (cls) ->
        throw new Error("Not implemented")

module.exports =
    HasOne: HasOne
    BelongsTo: BelongsTo
    HasMany: HasMany
    BelongsToMany: BelongsToMany
    MorphOne: MorphOne
    MorphTo: MorphTo

