{Rejected} = require '../utils'
cast = require './cast'

module.exports =
    # TODO: allow assignment with interim model
    assign: (model, relation, obj, options) ->
        if relation.options.through
            return Rejected new Error "Can't assign relation with interim model"
        foreignKey = @relatedData.key 'foreignKey'

        try
            related = cast.saveOrFetch this, obj, options, "Can't assign #{obj} to #{model} as a #{relation.name}"
            related.then (related) -> model.save(foreignKey, related.id, options)
        catch e
            Rejected e
