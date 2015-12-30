{Rejected, forceTransaction} = require '../utils'
{assign} = require './has_many'

module.exports =
    assign: assign

    attach: (model, relation, list, options) ->
        forceTransaction relation.model.transaction, options, (options) =>
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
                    list = saved.concat other
                    model.triggerThen('attaching', model, relation, list, options)
                    .then => @_originalAttach list, options
                    .then (result) ->
                        model.triggerThen('attached', model, relation, result, options)
            catch e
                Rejected e

    detach: (model, relation, list, options) ->
        forceTransaction relation.model.transaction, options, (options) =>
            model.triggerThen('detaching', model, relation, list, options)
            .then => @_originalDetach list, options
            .then (result) -> model.triggerThen('detached', model, relation, result, options)
