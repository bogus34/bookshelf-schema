{Rejected, Fulfilled} = require '../utils'

module.exports =
    forgeOrFetch: (self, obj, options, msg) ->
        model = self.model or self.constructor
        switch
            when obj is null
                Fulfilled null
            when typeof obj is 'number'
                model.forge(id: obj).fetch(options)
            when obj.constructor is Object
                Fulfilled model.forge(obj)
            when obj instanceof model
                Fulfilled obj
            else
                throw new Error msg

    saveOrFetch: (self, obj, options, msg) ->
        model = self.model or self.constructor
        switch
            when obj is null
                Fulfilled {id: null}
            when typeof obj is 'number'
                model.forge(id: obj).fetch(options)
            when obj.constructor is Object
                model.forge(obj).save(null, options)
            when obj instanceof model
                Fulfilled obj
            else
                throw new Error msg
