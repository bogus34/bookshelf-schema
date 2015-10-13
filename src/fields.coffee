class Field
    readable: true
    writable: true
    constructor: (name, options = {}) ->
        return new Field(name) unless this instanceof Field
        @name = name
        @options = options
        @options.createProperty ?= true
    pluginOption: (name) -> @model.__bookshelf_schema_options[name]
    contributeToSchema: (schema) -> schema.push this
    contributeToModel: (cls) ->
        @model = cls
        @model.__bookshelf_schema ?=
            validations: {}
            parsers: []
            formatters: []
        if @options.createProperty and @pluginOption('createProperties')
            @_createProperty(cls)
        if @pluginOption('validation')
            @_appendValidations(cls)

    validations: -> []
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
        spec.get = @createGetter() if @readable
        spec.set = @createSetter() if @writable
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
            when typeof value is 'object' and not isArray(value)
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

class NumberField extends Field
    constructor: (name, options) ->
        return new NumberField(name, options) unless this instanceof NumberField
        super name, options

    validations: ->
        result = super
        @acceptsRule result, ['naturalNonZero', 'positive']
        @acceptsRule result, 'natural'
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
        result.unshift @_withMessage 'integer'
        result

class FloatField extends NumberField
    constructor: (name, options) ->
        return new FloatField(name, options) unless this instanceof FloatField
        super name, options

    validations: ->
        result = super
        result.unshift @_withMessage 'numeric'
        result

class BooleanField extends Field
    constructor: (name, options) ->
        return new BooleanField(name, options) unless this instanceof BooleanField
        super name, options

class DateTimeField extends Field
    constructor: (name, options) ->
        return new DateTimeField(name, options) unless this instanceof DateTimeField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage @_validateDatetime
        result

    _validateDatetime: (value) ->
        return true if value instanceof Date
        return true if typeof value is 'string' and not isNaN(Date.parse(value))
        false

class DateField extends DateTimeField
    constructor: (name, options) ->
        return new DateTime(name, options) unless this instanceof DateField
        super name, options

class JSONField extends Field
    constructor: (name, options) ->
        return new JSONField(name, options) unless this instanceof JSONField
        super name, options

    validations: ->
        result = super
        result.push @_withMessage @_validateJSON
        result

    _validateJSON: (value) ->
        return true if typeof value is 'object'
        return false unless typeof value is 'string'
        JSON.parse value
        true

module.exports =
    Field: Field
    StringField: StringField
    EmailField: EmailField
    NumberField: NumberField
    IntField: IntField
    FloatField: FloatField
    BooleanField: BooleanField
    DateTimeField: DateTimeField
    DateField: DateField
    JSONField: JSONField
