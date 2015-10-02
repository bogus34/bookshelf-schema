class Field
    readable: true
    writable: true
    constructor: (name) ->
        return new Field(name) unless this instanceof Field
        @name = name
    contributeToSchema: (schema) -> schema.push this
    contributeToModel: (cls) ->
        @_createProperty(cls)

    _createProperty: (cls) ->
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
    constructor: (name) ->
        return new StringField(name) unless this instanceof StringField
        super name

class EmailField extends StringField
    constructor: (name) ->
        return new EmailField(name) unless this instanceof EmailField
        super name

class NumberField extends Field
    constructor: (name) ->
        return new NumberField(name) unless this instanceof NumberField
        super name

class IntField extends NumberField
    constructor: (name) ->
        return new IntField(name) unless this instanceof IntField
        super name

class FloatField extends NumberField
    constructor: (name) ->
        return new FloatField(name) unless this instanceof FloatField
        super name

class BooleanField extends Field
    constructor: (name) ->
        return new BooleanField(name) unless this instanceof BooleanField
        super name

class DateTimeField extends Field
    constructor: (name) ->
        return new DateTimeField(name) unless this instanceof DateTimeField
        super name

class DateField extends DateTimeField
    constructor: (name) ->
        return new DateTime(name) unless this instanceof DateField
        super name

class JSONField extends Field
    constructor: (name) ->
        return new JSONField(name) unless this instanceof JSONField
        super name

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
