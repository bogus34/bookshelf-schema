{Rejected, Fulfilled} = require '../utils'
cast = require './cast'
fixedCount = require './count'

module.exports =
    count: (model, relation) -> fixedCount this

    # TODO: allow assignment with interim model
    assign: (model, relation, list, options) ->
        if relation.options.through
            return Rejected new Error "Can't assign relation with interim model"
        list ?= []
        list = [list] unless list instanceof Array

        relation._forceTransaction options, (options) =>
            try
                currentObjs = model[relation.name]().fetch(options)

                attachObjs = for obj in list
                    p = cast.forgeOrFetch this, obj, options, "Can't assign #{obj} to #{model} as a #{relation.name}"
                    continue unless p
                    p

                attachObjs = Promise.all attachObjs

                return Promise.all([currentObjs, attachObjs]).then ([currentObjs, attachObjs]) =>
                    currentObjs = currentObjs.models

                    idx = currentObjs.reduce (memo, obj) ->
                        memo[obj.id] = obj
                        memo
                    , {}

                    attachObjs = for obj in attachObjs
                        if obj.id? and idx[obj.id]
                            delete idx[obj.id]
                            continue
                        else
                            obj

                    detachObjs = (obj for k, obj of idx)

                    @detach(detachObjs, options).then => @attach(attachObjs, options)
            catch e
                Rejected e

    attach: (model, relation, list, options) ->
        return unless list?
        list = [list] unless list instanceof Array
        try
            unloaded = []
            created = []
            models = []
            for obj in list
                switch
                    when typeof obj is 'number'
                        unloaded.push obj
                    when obj.constructor is Object
                        created.push @model.forge(obj)
                    when obj instanceof @model
                        models.push obj
                    else
                        throw new Error("Can't attach #{obj} to #{model} as a #{relation.name}")

            loadUnloaded = if unloaded.length is 0
                Fulfilled @model.collection()
            else
                @model.collection().where(@model.idAttribute, 'in', unloaded).fetch(options)

            loadUnloaded.then (unloaded) =>
                unloaded = unloaded.models
                pending = for obj in unloaded.concat(created, models)
                    @_attachOne obj, options
                Promise.all pending
        catch e
            Rejected e

    _attachOne: (model, relation, obj, options) ->
        obj.set(@relatedData.key('foreignKey'), model.id).save(null, options)

    detach: (model, relation, list, options) ->
        return unless list?
        list = [list] unless list instanceof Array
        try
            unloaded = []
            models = []
            for obj in list
                switch
                    when typeof obj is 'number'
                        unloaded.push obj
                    when obj instanceof @model
                        models.push obj
                    else
                        throw new Error("Can't detach #{obj} from #{model} #{relation.name}")

            loadUnloaded = if unloaded.length is 0
                Fulfilled @model.collection()
            else
                @model.collection().where(@model.idAttribute, 'in', unloaded).fetch(options)

            loadUnloaded.then (unloaded) =>
                unloaded = unloaded.models
                pending = for obj in unloaded.concat(models)
                    @_detachOne obj, options
                Promise.all pending
        catch e
            Rejected e

    _detachOne: (model, relation, obj, options) ->
        obj.set(@relatedData.key('foreignKey'), null).save(null, options)
