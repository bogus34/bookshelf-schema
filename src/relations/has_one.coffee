{Rejected} = require '../utils'
cast = require './cast'

module.exports =
    # TODO: allow assignment with interim model
    assign: (model, relation, obj, options) ->
        if relation.options.through
            return Rejected new Error "Can't assign relation with interim model"
        foreignKey = @relatedData.key 'foreignKey'

        try
            obj = cast.forgeOrFetch this, obj, options, "Can't assign #{obj} to #{model} as a #{relation.name}"
            old = model[relation.name]().fetch(options)

            Promise.all([old, obj]).then ([old, obj]) ->
                pending = []
                if old.id?
                    old = old.clone() # force knex not to use relatedData
                    pending.push old.save(foreignKey, null, options)
                if obj?
                    obj.set(foreignKey, model.id)
                    pending.push obj.save(null, options)
                Promise.all pending
        catch e
            Rejected e
