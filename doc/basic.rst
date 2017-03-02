Basic usage
===========

CoffeeScript
------------

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
----------

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
may see some of them in examples above: StringField, EmailField, HasMany.

You may define your own schema entities with custom behaviour.

Plugin options
--------------

.. function:: Schema(options = {})

Options:

**createProperties**: Boolean, default true
  should fields and relations create accessors or not

**validation**: Boolean
  enable model validation

**relationsAccessorPrefix**: String
  prefix for relations accessors

**language**, **labels**, **messages**
  are passed to Checkit_

.. _Checkit: https://github.com/tgriesser/checkit
