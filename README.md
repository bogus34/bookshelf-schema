bookshelf-schema
================

[![Documentation](https://readthedocs.org/projects/bookshelf-schema/badge/)](http://bookshelf-schema.readthedocs.org/)

The Bookshelf plugin that adds fields, relations, scopes and more to bookshelf models.

Like a [bookshelf-fields](https://github.com/bogus34/bookshelf-fields) but better.

[Documentation on readthedocs.org](http://bookshelf-schema.readthedocs.org/)

Usage
-----

```coffee
class User extends db.Model
    tableName: 'users'
    @schema [
        EmailField 'email'
        EncryptedStringField 'password'
        BooleanField 'active'
        HasMany 'Photo'
        Scope 'isActive', -> @where active: true
    ]
```

or

```javascript
User = db.Model.extend({ tableName: 'users'}, {
    schema: [
        EmailField('email'),
        EncryptedStringField('password'),
        BooleanField('active'),
        HasMany('Photo'),
        Scope('isActive', function(){ return this.where({active: true}; }))
    ]
});
```

Installation
------------

`npm install bookshelf-schema`

And then 

`bookshelf.plugin require('bookshelf-schema')()`
