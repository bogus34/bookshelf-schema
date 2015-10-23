{Rejected} = require '../utils'
cast = require './cast'

module.exports =
    assign: (model, relation, obj, options) ->
        foreignKey = @relatedData.key 'foreignKey'
        morphKey = @relatedData.key 'morphKey'
        morphValue = @relatedData.key 'morphValue'

        try
            obj = cast.forgeOrFetch this, obj, options, "Can't assign #{obj} to #{model} as a #{relation.name}"
            old = model[relation.name]().fetch(options)

            Promise.all([old, obj]).then ([old, obj]) ->
                pending = []
                if old.id?
                    old = old.clone() # force knex not to use relatedData
                    old.set foreignKey, null
                    old.set morphKey, null
                    pending.push old.save(null, options)
                if obj?
                    obj.set foreignKey, model.id
                    obj.set morphKey, morphValue
                    pending.push obj.save(null, options)
                Promise.all pending
        catch e
            Rejected e
