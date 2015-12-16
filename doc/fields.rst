Fields
======

.. note:: Exported from bookshelf-schema/lib/fields.

Fields enhances models in several ways:

- each field adds an accessor property so instead of calling :code:`model.get('fieldName')` you may
  use :code:`model.fieldName` directly

- each field may convert data when model is parsed or formatted

- model may use field-specific validation before save or explicitly. Validation uses the checkit_
  module.

Examples
--------

CoffeeScript
^^^^^^^^^^^^

.. code-block:: coffee

   {StringField, EncryptedStringField} = require 'bookshelf-schema/lib/fields'

   class User extends db.Model
     tableName: 'users'
     @schema [
       StringField 'username', required: true
       EncryptedStringField 'password', algorithm: sha256, minLength: 8
     ]

   User.forge(username: 'alice', password: 'secret-password').save()  # [1]
   .then (alice) ->
     User.forge(id: alice.id).fetch()
   .then (alice) ->
     alice.username.should.equal 'alice'                              # [2]
     alice.password.verify('secret-password').should.be.true          # [3]

JavaScript
^^^^^^^^^^

.. code-block:: js

   var Fields = require('bookshelf-schema/lib/fields');
   var StringField = Fields.StringField;
   var EncryptedStringField = Fields.EncryptedStringField;

   var User = db.Model.extend( { tableName: 'users' }, {
     schema: [
       StringField('username', {required: true}),
       EncryptedStringField('password', {algorithm: sha256, minLength: 8})
     ]
   });

   User.forge({username: 'alice', password: 'secret-password'}).save()  # [1]
   .then( function(alice) {
     return User.forge(id: alice.id).fetch()
   }).then( function(aclice) {
     alice.username.should.equal('alice');                              # [2]
     alice.password.verify('secret-password').should.be.true;           # [3]
   });


- **[1]**: model is validated before save
- **[2]**: alice.get('username') is called internally
- **[3]**: password field is converted to special object when fetched from database. Note that when
  alice is saved it doesn't refetch itself so password isn't parsed and :code:`alice.password`
  remains plain string 'secret-password'

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

EncryptedStringField
^^^^^^^^^^^^^^^^^^^^

.. class:: EncryptedStringField(name, options = {})

Options:

- **algorithm**: Function, required - function that will take string as an argument and return encrypted value
- **salt**: Boolean, default true - use salt when storing this field
- **saltLength**: Integer, default 5 - salt length
- **saltAlgorithm**: Function - function used to generate salt. Should take salt length as a parameter.
- **minLength** | **min_length**: Integer
- **maxLength** | **max_length**: Integer

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
