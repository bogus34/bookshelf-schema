Options
=======

.. note:: Exported from bookshelf-schema/lib/options

Sets plugin options for specific model

Examples
--------

CoffeeScript
^^^^^^^^^^^^

.. code-block:: coffee


   Options = require 'bookshelf-schema/lib/options'

   class User extends db.Model
     tableName: 'users'
     @schema [
       Options validation: false                     # [1]
     ]

JavaScript
^^^^^^^^^^

.. code-block:: js

   var Options = require('bookshelf-schema/lib/options')

   var User = db.Model.extend({ tableName: 'users' }, {
     schema: [ Options({ validation: false }) ]      // [1]
   });

- **[1]** disable validation for model User


Class Options
-------------

.. class:: Options(options)

   :param Object options: merged with plugin options and stored in model class

