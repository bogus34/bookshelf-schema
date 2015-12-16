Relations
=========

.. note:: Exported from bookshelf-schema/lib/relations.

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
       HasMany(Photo, {onDestroy: 'cascade'})            # [1]
     ]
   });

   User.forge({username: 'alice'}).fetch()
   .then( function(alice) {
     return alice.load('photos');                        # [2]
   }).then ( function(alice) {
     alice.$photos.at(0).should.be.an.instanceof(Photo); # [3]
   });

- **[1]** in that case HasMany will infer relation name from the name of related model and set it to
  'photos'

- **[1]** if you are using *registry* plugin you may use model name instead of class. It will be resolved in a lazy manner.

- **[2]** load will work like in vanilla bookshelf thanks to auto-generated method 'photos'

- **[3]** $photos internally calls :code:`alice.related('photos')` and returns fetched collection

Accessor helper methods
-----------------------

In addition to common collection or model methods accessors provides several helpers:

.. function:: assign(list, options = {})

   :param Array list: list of related models, ids, or plain objects
   :param Object options: options passed to save methods

   Called as :code:`alice.$photos.assign([ ... ])`

   It assign passed objects to relation. All related models that doesn't included to passed list
   will be detached. It will fetch passed ids and tries to creates new models for passed plain
   objects.

   For singular relations such as HasOne or BelongsTo it accepts one object instead of the list.

.. function:: attach(list, options = {})

   Similar to assign but only attaches objects.

.. function:: detach(list, options = {}

   Similar to assign but only detaches objects. Obviously it can't detach plain objects.
