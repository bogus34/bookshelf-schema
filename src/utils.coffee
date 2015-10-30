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
    ensurePromise: (x) ->
        if typeof x.then is 'function'
            x
        else
            utils.Fulfilled(x)
    values: (obj) -> v for k, v of obj
    pluck: (obj, fields...) ->
        return {} unless obj?
        result = {}
        for f in fields when f of obj
            result[f] = obj[f]
        result
    clone: (obj, options = {}) ->
        res = {}
        if options.only
            for k in options.only
                res[k] = obj[k]
        else
            for k of obj
                res[k] = obj[k]

        if options.expect
            for k in options.expect
                delete res[k]

        res
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
