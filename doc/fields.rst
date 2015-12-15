Fields
======

Fields are enhancing models in several ways:

- each field adds an accessor property so instead of calling :code:`model.get('fieldName')` you may
  use :code:`model.fieldName` directly

- each field may convert data when model is parsed or formatted

- model may use field-specific validation before save or explicitly. Validation is supplied with
  checkit_ module.

Every field options
-------------------

Fields are imported from "bookshelf-schema/lib/fields"

Each field is a subclass of Field class

.. class:: Field(name, options = {})

  :param String name: the name of the field
  :param Object options: field options

Options:

- **createProperty**: Boolean, default true - create accessor for this field
- **validation**: Boolean, default true - enable validation of this field value
- **message**: String - used as a default error message
- **label**: String - used as a field label when formatting error messages
- **validations**: Array - array of validation rules that checkit_ can understand

Field classes
-------------

StringField
^^^^^^^^^^^

.. class:: StringField(name, options = {})

Options:

- **minLength** | **min_length**: Integer
- **maxLength** | **max_length**: Integer

EmailField
^^^^^^^^^^

.. class:: EmailField(name, options = {})


Like a StringField with simple check that value looks like a email address.

NumberField
^^^^^^^^^^^

.. class:: NumberField(name, options = {})

Options:

- **greaterThan** | **greater_than** | **gt**: Number
- **greaterThanEqualTo** | **greater_than_equal_to** | **gte** | **min**: Number
- **lessThan** | **less_than** | **lt**: Number
- **lessThanEqualTo** | **less_than_equal_to** | **lte** | **max**: Number

IntField
^^^^^^^^

.. class:: IntField(name, options = {})

NumberField checked to be an Integer.

Options (in addition to options from NumberField):

- **naturalNonZero** | **positive**: Boolean
- **natural**: Boolean

FloatField
^^^^^^^^^^

.. class:: FloatField(name, options = {})


NumberField checked to be Float

BooleanField
^^^^^^^^^^^^

.. class:: BooleanField(name, options = {})

Converts value to Boolean

DateTimeField
^^^^^^^^^^^^^

.. class:: DateTimeField(name, options = {})

Validates that value is a Date or a string than can be parsed as Date.
Converts value to Date.

DateField
^^^^^^^^^

.. class:: DateField(name, options = {})

DateTimeField with stripped Time part.

JSONField
^^^^^^^^^

.. class:: JSONField(name, options = {})

Validates that value is object or a valid JSON string. Parses string from JSON when loaded and
stringifies to JSON when formatted.

Advanced validation
-------------------

- you may assign object instead of value to validation options::

    minLength: {value: 10, message: '{{label}} is too short to be valid!'}

- you may add complete checkit validation rules to field with validations option::

    StringField 'username', validations: [{rule: 'minLength:5'}]

.. _checkit: https://github.com/tgriesser/checkit
