Relations
=========

.. note:: Exported from bookshelf-schema/lib/relations

Relations are used to declare relations between models.

When applied to model it will

- create function that returns appropriate model or collection, like you normally does when define
  relations for bookshelf models

- create accessor prefixed by '$' symbol (may be configured)

- may prevent destroying of parent model or react by cascade destroying of related models or
  detaching them

Examples
--------

CoffeeScript
^^^^^^^^^^^^

.. code-block:: coffee

   {HasMany} = require 'bookshelf-schema/lib/relations'

   class Photo extends db.Model
     tableName: 'photos'

   class User extends db.Model
     tableName: 'users'
     @schema [
       StringField 'username'
       HasMany Photo, onDestroy: 'cascade'               # [1]
     ]

   User.forge(username: 'alice').fetch()
   .then (alice) ->
     alice.load('photos')                                # [2]
   .then (alice) ->
     alice.$photos.at(0).should.be.an.instanceof Photo   # [3]

JavaScript
^^^^^^^^^^

.. code-block:: js

   var Relations = require('bookshelf-schema/lib/relations');
   var HasMany = Relations.HasMany;

   var Photo = db.Model.extend({ tableName: 'photos' });
   var User = db.Model.extend({ tableName: 'users' }, {
     schema: [
       StringField('username'),
       HasMany(Photo, {onDestroy: 'cascade'})            // [1]
     ]
   });

   User.forge({username: 'alice'}).fetch()
   .then( function(alice) {
     return alice.load('photos');                        // [2]
   }).then ( function(alice) {
     alice.$photos.at(0).should.be.an.instanceof(Photo); // [3]
   });

- **[1]** HasMany will infer relation name from the name of related model and set it to 'photos'

  When relation name is generated from model name it uses model name with lower first letter and
  pluralize it for multiple relations.

- **[1]** when used with *registry* plugin you may use model name instead of class. It will be resolved in a lazy manner.

- **[2]** load will work like in vanilla bookshelf thanks to auto-generated method 'photos'

- **[3]** $photos internally calls :code:`alice.related('photos')` and returns fetched collection

Accessor helper methods
-----------------------

In addition to common collection or model methods accessors provides several helpers:

.. function:: assign(list, options = {})

   :param Array list: list of related models, ids, or plain objects
   :param Object options: options passed to save methods

   :code:`alice.$photos.assign([ ... ])`

   Assigns passed objects to relation. All related models that doesn't included to passed list
   will be detached. It will fetch passed ids and tries to creates new models for passed plain
   objects.

   For singular relations such as HasOne or BelongsTo it accepts one object instead of list.

.. function:: attach(list, options = {})

   :code:`alice.$photos.attach([ ... ])`

   Similar to assign but only attaches objects.

.. function:: detach(list, options = {}

   :code:`alice.$photos.detach([ ... ])`

   Similar to assign but only detaches objects. Obviously it can't detach plain objects.

Base class
----------

All relations are a subclass of Relation class.

.. class:: Relation(model, options = {})

   :param (Class|String) model: related model class. Could be a string if used with registry plugin.
   :param Object options: relation options

Options:

**createProperty**: Boolean, default true
    create accessors for this relation

**accessorPrefix**: String, default "$"
    used to generate name of accessor property

**onDestroy**: String, one of "ignore", "cascade", "reject", "detach", default "ignore"
    determines what to do when parend model gets destroyed

    - ignore - do nothing
    - cascade - destroy related models
    - reject - prevent parent model destruction if there is related models
    - detach - detach related models first

**through**: (Class|String)
    generate "through" relation

Relation classes
----------------

HasOne
^^^^^^

.. class:: HasOne(model, options = {})

BelongsTo
^^^^^^^^^

.. class:: BelongsTo(model, options = {})

Adds IntField <name>_id to model schema

HasMany
^^^^^^^

.. class:: HasMany(model, options = {})

MorphOne
^^^^^^^^

.. class:: MorphOne(model, polymorphicName, options = {})

   :param String polymorphicName:

Options:

**columnNames**: [String, String]
    First is a database column for related id, second - for related type

**morphValue**: String, defaults to target model tablename
    The string value associated with this relation.

MorphMany
^^^^^^^^^

.. class:: MorphMany(model, polymorphicName, options = {})

   :param String polymorphicName:

Options:

**columnNames**: [String, String]
    First is a database column for related id, second - for related type

**morphValue**: String, defaults to target model tablename
    The string value associated with this relation.


MorphTo
^^^^^^^

.. class:: MorphTo(polymorphicName, targets, options = {})

   :param String polymorphicName:
   :param Array targets: list of target models

Options:

**columnNames**: [String, String]
    First is a database column for related id, second - for related type

Adds IntField <name>_id or columnNames[0] to model schema

Adds StringField <name>_type of columnNames[1] to model schema
