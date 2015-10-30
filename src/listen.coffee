###
#
#  Listen 'fetched', 'onFetched'
#  Listen 'fetched', -> log 'model fetched'
#
###

{ensurePromise} = require './utils'

class Listen
    constructor: (event, callbacks...) ->
        return new Listen(event, callbacks...) unless this instanceof Listen
        @event = event
        if typeof callbacks[callbacks.length - 1] is 'object'
            @options = callbacks.pop()
        else
            @options = {}
        @callbacks = callbacks

    contributeToSchema: (schema) -> schema.push this
    contributeToModel: ->

    initialize: (instance) ->
        fns = (@_bindCallback(c, instance) for c in @callbacks)

        listener = if @options.condition
            condition = @_bindCallback(@options.condition, instance)
            (args...) ->
                ensurePromise(condition(args...))
                .then (result) ->
                    f(args...) for f in fns if result
        else
            (args...) -> f(args...) for f in fns

        instance.on @event, listener

    _bindCallback: (c, instance) ->
        if typeof c is 'string'
            instance[c].bind(instance)
        else
            c.bind(instance)

module.exports = Listen
