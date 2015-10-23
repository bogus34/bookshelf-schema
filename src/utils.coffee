utils =
    Fulfilled: (value) -> new Promise (resolve, reject) -> resolve(value)
    Rejected: (e) -> new Promise (resolve, reject) -> reject(e)
    promiseFinally: (p, callback) ->
        p.then( (v) ->
            callback()
            v
        , (e) ->
            callback()
            throw e
        )
    values: (obj) -> v for k, v of obj
    pluck: (obj, fields...) ->
        return {} unless obj?
        result = {}
        for f in fields when f of obj
            result[f] = obj[f]
        result
    upperFirst: (str) -> str[0].toUpperCase() + str[1..]
    forceTransaction: (transaction, options, callback) ->
        options ?= {}

        if options.transacting?
            callback(options)
        else
            transaction (trx) ->
                oldTtransacting = options.transacting
                options.transacting = trx
                utils.promiseFinally callback(options), ->
                    options.transacting = oldTtransacting

module.exports = utils
