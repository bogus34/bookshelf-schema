Overview
========

The Bookshelf_ plugin that enhances its models interface.

It provides helpers for dealing with model fields from bookshelf-fields_ and also helpers for
delaling with relations, scopes and more.

Related plugins
---------------

- bookshelf-fields_ - the ancestor ot this plugin
- bookshelf-scopes_ - the source of inspiration for scopes helpers

Basic usage
-----------

CoffeeScript
^^^^^^^^^^^^

.. highlight:: coffee

Enable plugin::

  Schema = require 'bookshelf-schema'
  knex = require('knex')({...})
  db = require('bookshelf')(knex)
  db.plugin Schema({...})

Define model::

  {StringField, EmailField} = require 'bookshelf-schema/lib/fields'
  {HasMany} = require 'bookshelf-schema/lib/relations'
  Photo = require './photo'

  class User extends db.Model
    tableName: 'users'
    @schema [
      StringField 'username'
      EmailField 'email'
      HasMany Photo
    ]

JavaScript
^^^^^^^^^^

.. highlight:: js

Enable plugin::

  var Schema = require('bookshelf-schema');
  var knex = require('knex')({...});
  var db = require('bookshelf')(knex);
  db.plugin(Schema({...}));

Define model::

  var Fields = require('bookshelf-schema/lib/fields'),
      StringField = Fields.StringField,
      EmailField = Fields.EmailField;

  var Relations = require('bookshelf-schema/lib/relations'),
      HasMany = Relations.HasMany;

  var Photo = require('./photo');

  var User = db.Model.extend({ tableName: 'users' }, {
    schema: [
      StringField('username'),
      EmailField('email'),
      HasMany(Photo)
    ]
  });


Schema definition
-----------------

Schema passed to :code:`db.Model.schema` method or to a "schema" static field is an array of "schema
entities". Each of that entity class defines special methods used in process of augementing and
initiaizing model.

The *bookshelf-schema* comes with several predefined classes adding fields, relations, scopes etc. You
already saw some of them in examples: StringField, EmailField, HasMany.

You may define your own schema entities that will use some
custom behaviour.

Plugin options
--------------

.. function:: Schema(options = {})

Options:

**createProperties**: Boolean, default true
  should fields and relations create accessors or not

**validation**: Boolean
  enable model validation

**language**, **labels**, **messages**
  are passed to checkit_

.. _Bookshelf: http://bookshelfjs.org/
.. _bookshelf-fields: https://github.com/bogus34/bookshelf-fields
.. _bookshelf-scopes: https://github.com/pk4media/bookshelf-scopes
.. _checkit: https://github.com/tgriesser/checkit
