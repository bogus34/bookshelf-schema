0.3.1
=====

* Add foreignKeyTarget, otherKeyTarget and throughForeignkeyTarget options for relations
* Fix relation option accessorPrefix and add plugin-wide relationsAccessorPrefix option

0.3.0
=====

* Add "column" option for fields
* Fix validation on saving with "patch" option

0.2.5
=====

* Fix HasMany.attach

0.2.4
=====

* Fix Listen to work with returned promises

0.2.3
=====

* Work around weird __proto__ manipulations used in Bookshelf.Model.extend (issue #4)
* Allow Bookshelf and Knex v0.10

0.2.2
=====

* Try to use related table name in addition to other methods to deduce relation name

0.2.1
=====

* Fix create additional fields in BelongsTo and MorphTo relations

0.2.0
=====

* Breaking change: rewrite Fields.EncryptedStringField. Use nodejs crypto api by default

0.1.1
=====

* Fix npm package

0.1.0
=====

* Initial release
