Fields
======

.. note:: Exported from bookshelf-schema/lib/fields

Fields enhances models in several ways:

- each field adds an accessor property so instead of calling :code:`model.get('fieldName')` you may
  use :code:`model.fieldName` directly

- each field may convert data when model is parsed or formatted

- model may use field-specific validation before save or explicitly. Validation uses the Checkit_
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
       EncryptedStringField 'password', minLength: 8
     ]

   User.forge(username: 'alice', password: 'secret-password').save()  # [1]
   .then (alice) ->
     User.forge(id: alice.id).fetch()
   .then (alice) ->
     alice.username.should.equal 'alice'                              # [2]
     alice.password.verify('secret-password').should.become.true      # [3]

JavaScript
^^^^^^^^^^

.. code-block:: js

   var Fields = require('bookshelf-schema/lib/fields');
   var StringField = Fields.StringField;
   var EncryptedStringField = Fields.EncryptedStringField;

   var User = db.Model.extend( { tableName: 'users' }, {
     schema: [
       StringField('username', {required: true}),
       EncryptedStringField('password', {minLength: 8})
     ]
   });

   User.forge({username: 'alice', password: 'secret-password'}).save()  // [1]
   .then( function(alice) {
     return User.forge({id: alice.id}).fetch()
   }).then( function(aclice) {
     alice.username.should.equal('alice');                              // [2]
     alice.password.verify('secret-password').should.become.true;       // [3]
   });


- **[1]**: model is validated before save
- **[2]**: alice.get('username') is called internally
- **[3]**: password field is converted to special object when fetched from database.

Validation
----------

.. function:: Model.prototype.validate()

   :returns: Promise[Checkit.Error]

Model method validate is called automatically before saving or may be called explicitly.
It takes validation rules added to model by fields and passes them to Checkit_.

You may override this method in your model to add custom validation logic.

Base class
----------

All fields are a subclass of Field class.

.. class:: Field(name, options = {})

  :param String name: the name of the field
  :param Object options: field options

Options:

**column**: String
    use passed string as a database column name instead of field name

**createProperty**: Boolean, default true
    create accessor for this field

**validation**: Boolean, default true
    enable validation of this field value

**message**: String
    used as a default error message

**label**: String
    used as a field label when formatting error messages

**validations**: Array
    array of validation rules that Checkit_ can understand

Field classes
-------------

StringField
^^^^^^^^^^^

.. class:: StringField(name, options = {})

Options:

**minLength** | **min_length**: Integer
    validate field value length is not lesser than minLength value

**maxLength** | **max_length**: Integer
    validate field value length is not greater than maxLength value

EmailField
^^^^^^^^^^

.. class:: EmailField(name, options = {})


Like a StringField with simple check that value looks like a email address.

UUIDField
^^^^^^^^^

.. class:: UUIDField(name, options = {})

Like as StringField that should be formatted as a UUID.

EncryptedStringField
^^^^^^^^^^^^^^^^^^^^

.. class:: EncryptedStringField(name, options = {})

Options:

**algorithm**: String | Function
    Function: function that will take string, salt, iteration count and key length as an arguments and
    return Promise with encrypted value

    String: algorithm name passed to crypto.pbkdf2

**iterations**: Integer
    iterations count passed to encryption function

**keylen**: Integer
    key length passed to encryption function

**saltLength**: Integer, default 16
    salt length in bytes

**saltAlgorithm**: Function
    function used to generate salt. Should take salt length as a parameter and return a Promise with
    salt value

**minLength** | **min_length**: Integer
    validate that unencrypted field value length is not lesser than minLength value
    checked only when unencrypted value available

**maxLength** | **max_length**: Integer
    validate that unencrypted field value length is not greater than maxLength value
    checked only when unencrypted value available

.. class:: EncryptedString

   Internal class used to handle encrypted value.

EncryptedStringField value became EncryptedString when saved. It looses it's plain value.
You should use method :code:`verify(value) : Promise` to verify value against saved string.

NumberField
^^^^^^^^^^^

.. class:: NumberField(name, options = {})

Options:

**greaterThan** | **greater_than** | **gt**: Number
    validates that field value is greater than option value

**greaterThanEqualTo** | **greater_than_equal_to** | **gte** | **min**: Number
    validates that field value is not lesser than option value

**lessThan** | **less_than** | **lt**: Number
    validates that field value is lesser than option value

**lessThanEqualTo** | **less_than_equal_to** | **lte** | **max**: Number
    validates that field value is not greater than option value

IntField
^^^^^^^^

.. class:: IntField(name, options = {})

NumberField checked to be an Integer.

Options (in addition to options from NumberField):

**naturalNonZero** | **positive**: Boolean
    validates that field value is positive

**natural**: Boolean
    validates that field value is positive or zero

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

- you may add complete Checkit validation rules to field with validations option::

    StringField 'username', validations: [{rule: 'minLength:5'}]

.. _Checkit: https://github.com/tgriesser/checkit
