Scopes
======

.. note:: Exported from bookshelf-schema/lib/scopes

Adds rails-like scopes to model.

Examples
--------

CoffeeScript
^^^^^^^^^^^^

.. code-block:: coffee

   Scope = require 'bookshelf-schema/lib/scopes'

   class User extends db.Model
     tableName: 'users'
     @schema [
       StringField 'username'
       BooleanField 'flag'
       Scope 'flagged', -> @where flag: true     # [1]
     ]

   class Group extends db.Model
     tableName: 'groups'
     @schema [
       BelongsToMany User
     ]

   User.flagged().fetchAll()
   .then (flaggedUsers) ->
     flaggedUsers.all('flag').should.be.true

   Group.forge(name: 'users').fetch()
   .then (group) ->
     group.$users.flagged().fetch()              # [2]
   .then (flaggedUsers) ->
     flaggedUsers.all('flag').should.be.true

JavaScript
^^^^^^^^^^

.. code-block:: js

   var Scope = require('bookshelf-schema/lib/scopes');

   var User = db.Model.extend( { tableName: 'users' }, {
     schema: [
       StringField('username'),
       BooleanField('flag'),
       Scope('flagged', function(){ this.where({ flag: true }); })  // [1]
     ]
   });

   var Group = db.Model.extend( {  tableName: 'groups' }, {
     schema: [ BelongsToMany(User) ]
   });

   User.flagged().fetchAll()
   .then( function(flaggedUsers) {
     flaggedUsers.all('flag').should.be.true;
   });

   Group.forge({ name: 'users' }).fetch()
   .then( function(group) {
     return group.$users.flagged().fetch()                          // [2]
   }).then( function(flaggedUsers) {
     flaggedUsers.all('flag').should.be.true;
   });

- **[1]**: scope function invoked in context of query builder, not model
- **[2]**: scopes from target model are automatically lifted to relation

Base class
----------

.. class:: Scope(name, builder)

   :param String name: scope name
   :param Function builder: scope function

Default scope
-------------

Scope with name "default" is automatically applied when model is fetched from database.

Unscoped
--------

.. function:: Model.unscoped()
.. function:: Model.prototype.unscoped()
.. function:: Collection.unscoped()
.. function:: Collection.prototype.unscoped()

Model and Collection gets method *unscoped* that removes all applied scopes.
