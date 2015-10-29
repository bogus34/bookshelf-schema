###
#
#  Options validation: false
#
###

{clone} = require './utils'

class Options
    constructor: (options) ->
        return new Options(options) unless this instanceof Options
        @options = options

    # put this to the first place
    contributeToSchema: (schema) -> schema.unshift this
    contributeToModel: (cls) ->
        cls.__bookshelf_schema_options = clone cls.__bookshelf_schema_options
        for k, v of @options
            cls.__bookshelf_schema_options[k] = v
        undefined

module.exports = Options
