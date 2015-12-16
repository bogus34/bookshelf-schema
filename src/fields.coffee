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

    validations: ->
        result = if @options.validations
            @options.validations[..]
        else
            []
        @acceptsRule result, ['required', 'accepted', 'exists']
        result

    modelValidations: ->

    createGetter: ->
        name = @name
        -> @get name

    createSetter: ->
        name = @name
        (value) -> @set name, value

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
            if @name of meta.validations
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

alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!$%^&*()_+|~-=`{}[]:;<>?,./'
class EncryptedString
    constructor: (@algorithm, @encrypted, @plain, @options = {}) ->
        @options.salt ?= true
        @options.saltLength ?= 5

    encrypt: ->
        if @options.salt
            salt = @_genSalt(@options.saltLength)
            @encrypted = salt + @algorithm(salt + @plain)
        else
            @encrypted = @algorithm(@plain)

        @encrypted

    verify: (value) ->
        if @options.salt
            salt = @encrypted.substr(0, @options.saltLength)
            checked = @encrypted.substr(@options.saltLength)
            @algorithm(salt + value) == checked
        else
            @algorithm(value) == @encrypted

    _genSalt: (length) ->
        if @options.saltAlgorithm
            @options.saltAlgorithm(length)
        else
            salt = new Array(length)
            for i in [0...length]
                salt.push alphabet[Math.round(Math.random() * (alphabet.length - 1))]
            salt.join('')

class EncryptedStringField extends Field
    constructor: (name, options = {}) ->
        unless typeof options.algorithm is 'function'
            throw new Error('algorithm is required for EncryptedStringField')
        return new EncryptedStringField(name, options) unless this instanceof EncryptedStringField
        super name, options

    validations: ->
        result = super()
        @acceptsRule result, ['minLength', 'min_length'], @_validateMinLenghth
        @acceptsRule result, ['maxLength', 'max_length'], @_validateMaxLenghth
        result

    parse: (attrs, options) ->
        return attrs unless attrs[@name]?
        attrs[@name] = new EncryptedString(@options.algorithm, attrs[@name], null, @options)
        attrs

    format: (attrs, options) ->
        me = attrs[@name]
        return attrs unless me?

        attrs[@name] = switch
            when me instanceof EncryptedString and me.plain?
                # encrypt it
                me.encrypt()
            when me instanceof EncryptedString
                # use encrypted
                me.encrypted
            when typeof me is 'string'
                # the only case when encryptes field would be string is if new model is forged
                # or field is set to new value
                # reencrypt it
                enc = new EncryptedString(@options.algorithm, null, me, @options)
                enc.encrypt()
        attrs

    _validateMinLenghth: (value, minLength) ->
        return if value instanceof EncryptedString and not value.plain?
        value = if value instanceof EncryptedString then value.plain else value
        value.length >= minLength

    _validateMaxLenghth: (value, maxLength) ->
        return if value instanceof EncryptedString and not value.plain?
        value = if value instanceof EncryptedString then value.plain else value
        value.length <= maxLength

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
        attrs[@name] = parseInt attrs[@name] if attrs[@name]?

class FloatField extends NumberField
    constructor: (name, options) ->
        return new FloatField(name, options) unless this instanceof FloatField
        super name, options

    validations: ->
        result = super
        result.unshift @_withMessage 'numeric'
        result

    parse: (attrs) ->
        attrs[@name] = parseFloat attrs[@name] if attrs[@name]?

class BooleanField extends Field
    constructor: (name, options) ->
        return new BooleanField(name, options) unless this instanceof BooleanField
        super name, options

    parse: (attrs) ->
        attrs[@name] = !!attrs[@name] if @name of attrs

    format: (attrs) ->
        attrs[@name] = !!attrs[@name] if @name of attrs

class DateTimeField extends Field
    constructor: (name, options) ->
        return new DateTimeField(name, options) unless this instanceof DateTimeField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage @_validateDatetime
        result

    parse: (attrs) ->
         attrs[@name] = new Date(attrs[@name]) if attrs[@name]?

    format: (attrs) ->
        attrs[@name] = new Date(attrs[@name]) if attrs[@name]? and attrs[@name] not instanceof Date

    _validateDatetime: (value) ->
        return true if value instanceof Date
        return true if typeof value is 'string' and not isNaN(Date.parse(value))
        false

class DateField extends DateTimeField
    constructor: (name, options) ->
        return new DateField(name, options) unless this instanceof DateField
        super name, options

    parse: (attrs) ->
        if attrs[@name]?
            d = new Date(attrs[@name])
            attrs[@name] = new Date(d.getFullYear(), d.getMonth(), d.getDate())

    format: (attrs) ->
        if attrs[@name]?
            d = unless attrs[@name] instanceof Date then new Date(attrs[@name]) else attrs[@name]
            attrs[@name] = new Date(d.getFullYear(), d.getMonth(), d.getDate())

class JSONField extends Field
    constructor: (name, options) ->
        return new JSONField(name, options) unless this instanceof JSONField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage @_validateJSON
        result

    format: (attrs) ->
        return unless attrs[@name] and typeof attrs[@name] is 'object'
        attrs[@name] = JSON.stringify attrs[@name]

    parse: (attrs) ->
        return unless attrs[@name] and typeof attrs[@name] is 'string'
        attrs[@name] = JSON.parse attrs[@name]

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
