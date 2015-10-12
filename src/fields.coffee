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
        if @options.createProperty and @pluginOption('createProperties')
            @_createProperty(cls)

    _createProperty: (cls) ->
        return if @name is 'id' or @name of cls.prototype
        spec = {}
        spec.get = @createGetter() if @readable
        spec.set = @createSetter() if @writable
        Object.defineProperty cls.prototype, @name, spec

    createGetter: ->
        name = @name
        -> @get name

    createSetter: ->
        name = @name
        (value) -> @set name, value

class StringField extends Field
    constructor: (name, options) ->
        return new StringField(name, options) unless this instanceof StringField
        super name, options

class EmailField extends StringField
    constructor: (name, options) ->
        return new EmailField(name, options) unless this instanceof EmailField
        super name, options

class NumberField extends Field
    constructor: (name, options) ->
        return new NumberField(name, options) unless this instanceof NumberField
        super name, options

class IntField extends NumberField
    constructor: (name, options) ->
        return new IntField(name, options) unless this instanceof IntField
        super name, options

class FloatField extends NumberField
    constructor: (name, options) ->
        return new FloatField(name, options) unless this instanceof FloatField
        super name, options

class BooleanField extends Field
    constructor: (name, options) ->
        return new BooleanField(name, options) unless this instanceof BooleanField
        super name, options

class DateTimeField extends Field
    constructor: (name, options) ->
        return new DateTimeField(name, options) unless this instanceof DateTimeField
        super name, options

class DateField extends DateTimeField
    constructor: (name, options) ->
        return new DateTime(name, options) unless this instanceof DateField
        super name, options

class JSONField extends Field
    constructor: (name, options) ->
        return new JSONField(name, options) unless this instanceof JSONField
        super name, options

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
