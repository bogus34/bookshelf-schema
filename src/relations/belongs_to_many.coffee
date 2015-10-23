{Rejected} = require '../utils'
{count, assign} = require './has_many'

module.exports =
    count: count
    assign: assign

    attach: (model, relation, list, options) ->
        try
            unsaved = []
            other = []
            for obj in list
                switch
                    when typeof obj is 'number'
                        other.push obj
                    when obj instanceof @model and obj.id?
                        other.push obj
                    when obj instanceof @model
                        unsaved.push obj
                    when obj.constructor is Object
                        unsaved.push @model.forge(obj)
                    else
                        throw new Error("Can't attach #{obj} to #{model} as a #{relation.name}")

            unsaved = unsaved.map( (obj) -> obj.save(null, options) )
            Promise.all(unsaved).then (saved) =>
                @_originalAttach saved.concat(other), options
        catch e
            Rejected e
