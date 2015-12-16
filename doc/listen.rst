Listen
======

.. note:: Exported from bookshelf-schema/lib/listen

Declare event listener.

Examples
--------

CoffeeScript
^^^^^^^^^^^^

.. code-block:: coffee

   Listen = require 'bookshelf-schema/lib/listen'

   class User extends db.Model
     tableName: 'users'

     @schema [
       Listen 'saved', ( -> console.log "#{@username} saved" )
       Listen 'fetched', 'onFetched'
     ]

     onFetched: -> console.log "#{@username} fetched"

JavaScript
^^^^^^^^^^

.. code-block:: js

   var Listen = require('bookshelf-schema/lib/listen');

   var User = db.Model.extend( {
       tableName: 'users',
       onFetched: function() {
         console.log this.username + ' fetched';
       }
     }, {
       schema: [
         Listen('saved', function(){ console.log( this.username + ' saved'); }),
         Listen('fetched', 'onFetched')
       ]
   });

Callbacks are called in context of model instance.

Base class
----------

.. class:: Listen(event, callbacks...)

   :param String event:
   :param (Function|String) callback:

