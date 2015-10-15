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
#     photo.$user                             # RelationHelper
#     photo.$user = user                      # set user_id to user.id and save
#     photo.$user.transacting(t) = user       # set user_id to user.id and save within transaction
#
# User.forge(id: 1).fetch(withRelated: 'photos').then (user) ->
#     user.photos                             # function
#     user.related('photos')                  # Collection
#     user.$photos                            # RelationHelper
#     user.$photos = [...]                    # detach all photos and attach listed
#     user.$photos.transacting(t) = [...]
#     user.$photos.attach(...)                # attach listed photos and save them
#     user.$photos.transacting(t).attach(...) # attach listed photos and save them within transaction
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
class Relation
    constructor: ->
        return new Relation(arguments...) unless this instanceof Relation
        @_parseConstructorArguments()

    pluginOption: (name) -> @model.__bookshelf_schema_options[name]
    contributeToSchema: (schema) -> schema.push this
    contributeToModel: (cls) ->
        @model = cls
        @_createRelation(cls) unless @name of cls.prototype
        if (@options.createProperty || !@options.createProperty?) and @pluginOption('createProperties')
            @_createProperty(cls)

    _parseConstructorArguments: ->
        # name, model, options
        if arguments.length is 3
            @name = arguments[0]
            @relatedModel = arguments[1]
            @options = arguments[2]


        else if arguments.length is 2
            # model, options
            if typeof arguments[1] is 'object'
                @relatedModel = arguments[0]
                @name = @deduceName @relatedModel
                @options = arguments[1]

            # name, model
            else
                @name = arguments[0]
                @relatedModel = arguments[0]
                @options = {}
        # model
        else
            @relatedModel = arguments[0]
            @name = @deduceName @relatedModel

    _prefix: -> @options.prefix or @pluginOption('relationsPrefix') or '$'

    _createProperty: (cls) ->
        return if @name is 'id' or @name of cls.prototype
        name = @name
        spec =
            get: -> @related(name)

        Object.defineProperty cls.prototype, "#{@prefix()}#{@name}", spec

class HasOne extends Relation
    _createRelation: (cls) ->
        related = @relatedModel
        foreignKey = @options.foreignKey
        -> @hasOne related, foreignKey

class BelongsTo extends Relation
    _createRelation: (cls) ->
        related = @relatedModel
        foreignKey = @options.foreignKey
        -> @belongsTo related, foreignKey

class HasMany extends Relation
    _createRelation: (cls) ->
        related = @relatedModel
        foreignKey = @options.foreignKey
        -> @hasMany related, foreignKey

class BelongsToMany extends Relation
    _createRelation: (cls) ->
        related = @relatedModel
        table = @options.table
        foreignKey = @options.foreignKey
        otherKey = @options.otherKey
        -> @belongsToMany related, table, foreignKey, otherKey

class MorphOne extends Relation
    _createRelation: (cls) ->
        related = @relatedModel
        name = @options.name
        columnNames = @options.columnNames
        morphValue = @options.morphValue
        -> @morphOne related, name, columnNames, morphValue

class MorphMany extends Relation
    _createRelation: (cls) ->
        related = @relatedModel
        name = @options.name
        columnNames = @options.columnNames
        morphValue = @options.morphValue
        -> @morphMany related, name, columnNames, morphValue

class MorphTo extends Relation
    _createRelation: (cls) ->
        throw "Not implemented"

module.exports =
    HasOne: HasOne
    BelongsTo: BelongsTo
    HasMany: HasMany
    BelongsToMany: BelongsToMany
    MorphOne: MorphOne
    MorphTo: MorphTo

