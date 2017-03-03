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
        Scope('isActive', function(){ return this.where({active: true}); })
    ]
});
```

Installation
------------

`npm install bookshelf-schema`

And then 

`bookshelf.plugin require('bookshelf-schema')()`

Contributing
------------

- If you've found a bug or missed some feature - your are welcome to post an issue
- PRs are appreciated. But try to stay focused, if feature can be implemented as a separate project, keep it separately
- PRs to documentation a very appreciated too. English isn't my native language so I feel quite bad about documentation quality. Don't hesitate to spellcheck, reformulate or even rewrite parts of it completely
