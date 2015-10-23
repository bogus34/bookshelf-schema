{values} = require '../utils'

# Originally posted by @nathggns at https://github.com/tgriesser/bookshelf/issues/126
module.exports = (object) ->
    sync = object.sync()

    relatedData = sync.syncing.relatedData
    if relatedData.isJoined()
        relatedData.joinClauses sync.query
    relatedData.whereClauses sync.query

    sync.query.count('*')
    .then (result) ->
        throw new Error('Empty response') if !result
        Number values(result[0])[0]
