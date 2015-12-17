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
       Scope 'flagged', -> @where flag: true                   # [1]
       Scope 'nameStartsWith', (prefix) ->                     # [2]
         @where 'username', 'like', "#{prefix}%"
     ]

   class Group extends db.Model
     tableName: 'groups'
     @schema [
       BelongsToMany User
     ]

   User.flagged().fetchAll()
   .then (flaggedUsers) ->
     flaggedUsers.all('flag').should.be.true

   User.flagger().nameStartsWith('a').fetchAll()               # [3]
   .then (users) ->
     users.all('flag').should.be.true
     users.all( (u) -> u.username[0] is 'a' ).should.be.true

   Group.forge(name: 'users').fetch()
   .then (group) ->
     group.$users.flagged().fetch()                            # [4]
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
       Scope('flagged', function(){                           // [1]
         this.where({ flag: true });
       }),
       Scope('nameStartsWith', function(prefix) {             // [2]
         this.where('username', 'like', prefix + '%')
       })
     ]
   });

   var Group = db.Model.extend( {  tableName: 'groups' }, {
     schema: [ BelongsToMany(User) ]
   });

   User.flagged().fetchAll()
   .then( function(flaggedUsers) {
     flaggedUsers.all('flag').should.be.true;
   });

   User.flagged().nameStartsWith('a').fetchAll()              // [3]
   .then( function(users) {
     users.all('flag').should.be.true;
     users.all(function(u){
       return u.username[0] == 'a';
     }).should.be.true;
   });

   Group.forge({ name: 'users' }).fetch()
   .then( function(group) {
     return group.$users.flagged().fetch()                    // [4]
   }).then( function(flaggedUsers) {
     flaggedUsers.all('flag').should.be.true;
   });

- **[1]**: scope invoked in context of query builder, not model
- **[2]**: scopes are just a functions and may use an arguments
- **[3]**: scopes may be chained
- **[4]**: scopes from target model are automatically lifted to relation

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
