###
#
# StringField 'username', minLength: 3, maxLength: 10
# StringField 'username', validations: [{rule: 'minLength:3', message: 'Invalid username'}]
#
###

class Field
    constructor: (name, options = {}) ->
        return new Field(name) unless this instanceof Field
        @name = name
        @column = options.column or @name
        @options = options
    pluginOption: (name, defaultVal) ->
        if name of @model.__bookshelf_schema_options
            @model.__bookshelf_schema_options[name]
        else
            defaultVal
    option: (name, pluginOptionName, defaultVal) ->
        if arguments.length is 2
            defaultVal = pluginOptionName
            pluginOptionName = name
        value = @options[name]
        value = @pluginOption(pluginOptionName, defaultVal) unless value?
        value
    contributeToSchema: (schema) -> schema.push this
    contributeToModel: (cls) ->
        @model = cls
        @model.__bookshelf_schema ?=
            validations: {}
            parsers: []
            formatters: []
        if @option('createProperty', 'createProperties', true)
            @_createProperty(cls)
        if @option('validation', true)
            @_appendValidations(cls)
        @_appendFormatter()
        @_appendParser()
        @_appendAlias()

    validations: ->
        result = if @options.validations
            @options.validations[..]
        else
            []
        @acceptsRule result, ['required', 'accepted', 'exists']
        result

    modelValidations: ->

    createGetter: ->
        column = @column
        -> @get column

    createSetter: ->
        column = @column
        (value) -> @set column, value

    acceptsRule: (validations, names, rule) ->
        names = [names] unless names instanceof Array
        rule ?= names[0]
        for name in names when name of @options
            validations.push @_normalizeRule rule, @options[name]
            return

    _createProperty: (cls) ->
        return if @name is 'id' or @name of cls.prototype
        spec = {}
        getter = @createGetter()
        setter = @createSetter()
        spec.get = getter if getter
        spec.set = setter if setter
        Object.defineProperty cls.prototype, @name, spec

    _appendValidations: (model) ->
        meta = model.__bookshelf_schema

        validations = @validations()
        if validations and validations.length > 0
            if @column of meta.validations
                unless meta.validations[@name] instanceof Array
                    meta.validations[@name] = [meta.validations[@name]]
            else
                meta.validations[@name] = []
            meta.validations[@name].push.apply meta.validations[@name], validations

        modelValidations = @modelValidations()
        if modelValidations and modelValidations.length > 0
            meta.modelValidations ?= []
            meta.modelValidations.push.apply meta.modelValidations, modelValidations

    _normalizeRule: (rule, value) ->
        @_withMessage switch
            when typeof value is 'object' and value not instanceof Array
                result = rule: rule
                for k, v of value
                    result[k] = v
                if 'value' of result
                    if typeof rule is 'string'
                        result.rule += ':' + result.value
                    else
                        result.params = result.value
                    delete result.value
                result.params ||= []
                result
            when typeof value is 'boolean'
                rule
            when typeof rule is 'string'
                "#{rule}:#{value}"
            else
                @_normalizeRule rule, value: value

    _withMessage: (rule) ->
        return rule unless @options.message? or @options.label?
        rule = {rule: rule} if typeof rule isnt 'object'
        rule.message ?= @options.message if @options.message?
        rule.label ?= @options.label if @options.label?
        rule

    _appendFormatter: ->
        if typeof @format is 'function'
            @model.__bookshelf_schema.formatters.push @format.bind(this)

    _appendParser: ->
        if typeof @parse is 'function'
            @model.__bookshelf_schema.parsers.push @parse.bind(this)

    _appendAlias: ->
        if @column isnt @name
            @model.__bookshelf_schema.aliases ?= {}
            @model.__bookshelf_schema.aliases[@name] = @column

class StringField extends Field
    constructor: (name, options) ->
        return new StringField(name, options) unless this instanceof StringField
        super name, options

    validations: ->
        result = super
        @acceptsRule result, ['minLength', 'min_length']
        @acceptsRule result, ['maxLength', 'max_length']
        result

class EmailField extends StringField
    constructor: (name, options) ->
        return new EmailField(name, options) unless this instanceof EmailField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage 'email'
        result

class UUIDField extends StringField
    constructor: (name, options) ->
        return new UUIDField(name, options) unless this instanceof UUIDField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage 'uuid'
        result

class EncryptedString
    constructor: (@encrypted, @plain, @options = {}) ->
        @options.saltLength ?= 16

    encrypt: ->
        @_genSalt(@options.saltLength)
        .then (salt) =>
            @_genHash(@plain, salt)
            .then (hash) =>
                @encrypted = salt.toString('base64') + '$' + hash.toString('base64')

    verify: (value) ->
        checked = @encrypted.split('$')
        salt = new Buffer checked[0], 'base64'
        @_genHash(value, salt).then (hash) ->
            hash.toString('base64') is checked[1]

    _genSalt: (length) ->
        if @options.saltAlgorithm
            @options.saltAlgorithm length, callback
        else
            crypto = require 'crypto'
            new Promise (resolve, reject) ->
                crypto.randomBytes length, (err, salt) ->
                    if err
                        reject err
                    else
                        resolve salt

    _genHash: (plain, salt) ->
        iterations = @options.iterations or 1000
        keylen = @options.length or 512

        if typeof @options.algorithm is 'function'
            @options.algorithm plain, salt, iterations, keylen
        else
            crypto = require 'crypto'
            digest = if typeof @options.algorithm is 'string'
                @options.algorithm
            else
                'sha256'
            new Promise (resolve, reject) ->
                crypto.pbkdf2 plain, salt, iterations, keylen, digest, (err, hash) ->
                    if err
                        reject err
                    else
                        resolve hash

class EncryptedStringField extends Field
    constructor: (name, options = {}) ->
        return new EncryptedStringField(name, options) unless this instanceof EncryptedStringField
        super name, options

    validations: ->
        result = super()
        @acceptsRule result, ['minLength', 'min_length'], @_validateMinLenghth
        @acceptsRule result, ['maxLength', 'max_length'], @_validateMaxLenghth
        result

    initialize: (instance) ->
        instance.on 'saving', @_onSaving

    parse: (attrs, options) ->
        return attrs unless attrs[@column]?
        attrs[@column] = new EncryptedString(attrs[@column], null, @options)
        attrs

    format: (attrs, options) ->
        me = attrs[@column]
        return attrs unless me?
        unless me instanceof EncryptedString and me.encrypted
            throw new Error("Field @name should be encryted first")
        attrs[@column] = me.encrypted
        attrs

    _validateMinLenghth: (value, minLength) ->
        return if value instanceof EncryptedString and not value.plain?
        value = if value instanceof EncryptedString then value.plain else value
        value.length >= minLength

    _validateMaxLenghth: (value, maxLength) ->
        return if value instanceof EncryptedString and not value.plain?
        value = if value instanceof EncryptedString then value.plain else value
        value.length <= maxLength

    _onSaving: (instance, attrs, options) =>
        me = attrs[@column] or instance.attributes[@column]
        return unless me?
        return if me instanceof EncryptedString and not me.plain
        if me not instanceof EncryptedString
            me = attrs[@column] = instance.attributes[@column] = new EncryptedString null, me, @options
        me.encrypt()

class NumberField extends Field
    constructor: (name, options) ->
        return new NumberField(name, options) unless this instanceof NumberField
        super name, options

    validations: ->
        result = super
        @acceptsRule result, ['greaterThan', 'greater_than', 'gt']
        @acceptsRule result, ['greaterThanEqualTo', 'greater_than_equal_to', 'gte', 'min']
        @acceptsRule result, ['lessThan', 'less_than', 'lt']
        @acceptsRule result, ['lessThanEqualTo', 'less_than_equal_to', 'lte', 'max']
        result

class IntField extends NumberField
    constructor: (name, options) ->
        return new IntField(name, options) unless this instanceof IntField
        super name, options

    validations: ->
        result = super
        @acceptsRule result, ['naturalNonZero', 'positive']
        @acceptsRule result, 'natural'
        result.unshift @_withMessage 'integer'
        result

    parse: (attrs) ->
        attrs[@column] = parseInt attrs[@column] if attrs[@column]?

class FloatField extends NumberField
    constructor: (name, options) ->
        return new FloatField(name, options) unless this instanceof FloatField
        super name, options

    validations: ->
        result = super
        result.unshift @_withMessage 'numeric'
        result

    parse: (attrs) ->
        attrs[@column] = parseFloat attrs[@column] if attrs[@column]?

class BooleanField extends Field
    constructor: (name, options) ->
        return new BooleanField(name, options) unless this instanceof BooleanField
        super name, options

    parse: (attrs) ->
        attrs[@column] = !!attrs[@column] if @column of attrs

    format: (attrs) ->
        attrs[@column] = !!attrs[@column] if @column of attrs

class DateTimeField extends Field
    constructor: (name, options) ->
        return new DateTimeField(name, options) unless this instanceof DateTimeField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage @_validateDatetime
        result

    parse: (attrs) ->
        attrs[@column] = new Date(attrs[@column]) if attrs[@column]?

    format: (attrs) ->
        attrs[@column] = new Date(attrs[@column]) if attrs[@column]? and attrs[@column] not instanceof Date

    _validateDatetime: (value) ->
        return true if value instanceof Date
        return true if typeof value is 'string' and not isNaN(Date.parse(value))
        false

class DateField extends DateTimeField
    constructor: (name, options) ->
        return new DateField(name, options) unless this instanceof DateField
        super name, options

    parse: (attrs) ->
        if attrs[@column]?
            d = new Date(attrs[@column])
            attrs[@column] = new Date(d.getFullYear(), d.getMonth(), d.getDate())

    format: (attrs) ->
        if attrs[@column]?
            d = unless attrs[@column] instanceof Date then new Date(attrs[@column]) else attrs[@column]
            attrs[@column] = new Date(d.getFullYear(), d.getMonth(), d.getDate())

class JSONField extends Field
    constructor: (name, options) ->
        return new JSONField(name, options) unless this instanceof JSONField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage @_validateJSON
        result

    format: (attrs) ->
        return unless attrs[@column] and typeof attrs[@column] is 'object'
        attrs[@column] = JSON.stringify attrs[@column]

    parse: (attrs) ->
        return unless attrs[@column] and typeof attrs[@column] is 'string'
        attrs[@column] = JSON.parse attrs[@column]

    _validateJSON: (value) ->
        return true if typeof value is 'object'
        return false unless typeof value is 'string'
        JSON.parse value
        true

module.exports = {
    Field
    StringField
    EmailField
    EncryptedStringField
    NumberField
    IntField
    FloatField
    BooleanField
    DateTimeField
    DateField
    JSONField
}
