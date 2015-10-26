###
#
#  class User extends db.Model
#      tableName: 'users'
#
#      @schema [
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
#  class Group extends db.Model
#      tableName: 'groups'
#
#      @schema [
#          BelongsToMany User, query: -> @active()
#      ]
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
        cls::[@name] = @createScope()
        cls[@name] = @createStaticScope()

    createScope: ->
        self = this
        (args...) ->
            @_appliedScopes ?= []
            @_appliedScopes.push [self.name, self.builder, args]
            this

    createStaticScope: ->
        self = this
        ->
            instance = self.model.forge()
            instance[self.name].apply(instance, arguments)

module.exports = Scope
