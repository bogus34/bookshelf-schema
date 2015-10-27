###
#
#  class User extends db.Model
#      tableName: 'users'
#
#      @schema [
#          BelongsToMany Group, query: -> @userland()
#
#          Scope 'active', -> @where(active: true)
#          Scope 'withEmail', -> @where('email is not null')
#          Scope 'activeWithEmail', -> @active().withEmail()
#
#          Scope 'default', -> @where(deleted: false)
#      ]
#
#  User.active().fetchAll()
#  User.forge(username: 'alice').flagged().fetchAll()
#  User.unscoped().active().fetchAll()
#
#  alice = User.forge(...).fetch()
#  alice.$groups.named('wheel').fetchOne()
#  alice.$groups.unscoped().fetch()
#  alice.$groups.unscoped().count()
#
###

class Scope
    constructor: (name, builder) ->
        return new Scope(name, builder) unless this instanceof Scope
        @name = name
        @builder = builder

    contributeToSchema: (schema) -> schema.push this
    contributeToModel: (cls) ->
        @model = cls
        unless @name is 'default'
            cls::[@name] = @createScope()
            cls[@name] = @createStaticScope()
        else
            @model.__bookshelf_schema ?= {}
            @model.__bookshelf_schema.defaultScope = this

    apply: (obj, args) ->
        obj._appliedScopes ?= []
        obj._appliedScopes.push [@name, @builder, args]

    liftScope: (to) ->
        unless @name of to
            self = this
            to[@name] = (args...) ->
                self.apply(this, args)
                this

    createScope: ->
        self = this
        (args...) ->
            self.apply(this, args)
            this

    createStaticScope: ->
        self = this
        ->
            instance = @forge()
            instance[self.name].apply(instance, arguments)

module.exports = Scope
