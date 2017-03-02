Bookshelf = require 'bookshelf'
Schema = require '../src/'
init = require './init'
{StringField, BooleanField} = require '../src/fields'
{BelongsToMany} = require '../src/relations'
Scope = require '../src/scopes'

describe "Scopes", ->
    this.timeout 3000
    db = null
    User = null
    Group = null

    before co ->
        db = init.init()
        yield [
            init.users()
            init.groups()
        ]

    beforeEach ->
        class User extends db.Model
            tableName: 'users'

        class Group extends db.Model
            tableName: 'groups'

    afterEach -> init.truncate 'users'

    it 'creates scopes as a functions', ->
        User.schema [
            Scope 'flagged', ->
        ]

        expect(User.flagged).to.be.a.function
        expect(User::flagged).to.be.a.function

    describe 'applies scope', ->
        beforeEach co ->
            User.schema [
                StringField 'username'
                BooleanField 'flag'
                Scope 'flagged', -> @where flag: true
            ]

            yield [
                 new User(username: 'alice', flag: true).save()
                 new User(username: 'bob', flag: false).save()
            ]

        it 'with fetchAll', co ->
            flagged = yield User.flagged().fetchAll()
            flagged.should.be.an.instanceof db.Collection
            flagged.length.should.equal 1
            flagged.at(0).flag.should.be.true

        it 'with fetch', co ->
            flagged = yield User.flagged().fetch()
            flagged.should.be.an.instanceof User
            flagged.flag.should.be.true

        it 'with count', ->
            User.flagged().count().then(parseInt).should.become 1

    describe 'applies chained scopes', ->
        beforeEach co ->
            User.schema [
                StringField 'username'
                BooleanField 'flag'
                Scope 'flagged', -> @where flag: true
                Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
            ]

            yield [
                 new User(username: 'alice', flag: true).save()
                 new User(username: 'bob', flag: true).save()
                 new User(username: 'alan', flag: false).save()
            ]

        it 'with fetchAll', co ->
            result = yield User.flagged().nameStartsWith('a').fetchAll()
            result.should.be.an.instanceof db.Collection
            result.length.should.equal 1
            result.at(0).username.should.equal 'alice'

        it 'with fetch', co ->
            result = yield User.flagged().nameStartsWith('a').fetch()
            result.should.be.an.instanceof User
            result.username.should.equal 'alice'

        it 'with count', ->
            User.flagged().nameStartsWith('a').count().then(parseInt).should.become 1

    it 'applies default scope', co ->
        User.schema [
            StringField 'username'
            BooleanField 'flag'
            Scope 'default', -> @where flag: true
        ]
        yield [
             new User(username: 'alice', flag: true).save()
             new User(username: 'bob', flag: false).save()
        ]

        result = yield User.fetchAll()
        result.length.should.equal 1
        result = yield User.unscoped().fetchAll()
        result.length.should.equal 2

    it 'can chain scope next to unscoped', co ->
        User.schema [
            StringField 'username'
            BooleanField 'flag'
            Scope 'default', -> @where flag: true
            Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
        ]
        yield [
             new User(username: 'alice', flag: false).save()
             new User(username: 'bob', flag: false).save()
        ]

        result = yield User.unscoped().nameStartsWith('a').fetchAll()
        result.length.should.equal 1
        result.at(0).username.should.equal 'alice'

    describe 'on relations', ->
        beforeEach co ->
            users = yield [
                 new User(username: 'alice', flag: true).save()
                 new User(username: 'bob', flag: true).save()
                 new User(username: 'alan', flag: false).save()
                 new User(username: 'charley', flag: true).save()
            ]

            groups = yield [
                new Group(name: 'wheel').save()
                new Group(name: 'users').save()
            ]

            yield [
                # alice is wheel
                db.knex('groups_users').insert(user_id: users[0].id, group_id: groups[0].id)
                # bob, alan and charley are users
                db.knex('groups_users').insert(user_id: users[1].id, group_id: groups[1].id)
                db.knex('groups_users').insert(user_id: users[2].id, group_id: groups[1].id)
                db.knex('groups_users').insert(user_id: users[3].id, group_id: groups[1].id)
            ]

        afterEach -> init.truncate 'groups', 'groups_users'

        describe 'BelongsToMany', ->
            beforeEach co ->
                User.schema [
                    StringField 'username'
                    Scope 'flagged', -> @where flag: true
                    Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
                ]

                Group.schema [
                    StringField 'name'
                    BelongsToMany User
                    BelongsToMany User, name: 'flaggedUsers', query: -> @flagged()
                ]

            it 'fetch', co ->
                wheel = yield new Group(name: 'wheel').fetch()
                wheelUsers = yield wheel.$users.flagged().fetch()
                wheelUsers.should.be.an.instanceof db.Collection
                wheelUsers.length.should.equal 1
                wheelUsers.at(0).username.should.equal 'alice'

            it 'count', co ->
                wheel = yield new Group(name: 'wheel').fetch()
                wheel.$users.count().should.become 1

            it 'scope in relation definition', co ->
                users = yield new Group(name: 'users').fetch()
                yield users.$users.count().should.become 3
                yield users.$flaggedUsers.count().should.become 2
                usersUsers = yield users.$flaggedUsers.fetch()
                usersUsers.should.be.an.instanceof db.Collection
                usersUsers.length.should.equal 2
                usersUsers.at(0).username.should.equal 'bob'

            it 'chaining scopes', co ->
                users = yield new Group(name: 'users').fetch()
                yield users.$users.flagged().nameStartsWith('b').count().should.become 1
                result = yield users.$users.flagged().nameStartsWith('b').fetch()
                result.length.should.equal 1
                result.at(0).username.should.equal 'bob'

        describe "doesn't affects cached relation", ->
            beforeEach co ->
                Group.schema [
                    StringField 'name'
                    BelongsToMany User
                ]

            it 'with scope, then without', co ->
                User.schema [
                    Scope 'flagged', -> @where flag: true
                    Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
                ]
                group = yield new Group(name: 'users').fetch()
                flagged = yield group.$users.flagged().fetch()
                all = yield group.$users.fetch()
                flagged2 = yield group.$users.flagged().fetch()

                flagged.length.should.equal 2
                all.length.should.equal 3
                flagged2.length.should.equal 2
                group.$users.length.should.equal 3

            it 'with default scope, then with scope', co ->
                User.schema [
                    Scope 'default', -> @where flag: true
                    Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
                ]
                group = yield new Group(name: 'users').fetch()
                flagged = yield group.$users.fetch()
                none = yield group.$users.nameStartsWith('a').fetch()

                flagged.length.should.equal 2
                none.length.should.equal 0
                group.$users.length.should.equal 2

            it 'with scope, then with default scope', co ->
                User.schema [
                    Scope 'default', -> @where flag: true
                    Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
                ]
                group = yield new Group(name: 'users').fetch()
                bob = yield group.$users.nameStartsWith('b').fetch()
                flagged = yield group.$users.fetch()

                bob.length.should.equal 1
                flagged.length.should.equal 2
                group.$users.length.should.equal 2

            it 'with default scope, then unscoped', co ->
                User.schema [
                    Scope 'default', -> @where flag: true
                    Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
                ]
                group = yield new Group(name: 'users').fetch()
                flagged = yield group.$users.fetch()
                all = yield group.$users.unscoped().fetch()

                flagged.length.should.equal 2
                all.length.should.equal 3
                group.$users.length.should.equal 2

            it 'unscoped, then with default scope', co ->
                User.schema [
                    Scope 'default', -> @where flag: true
                    Scope 'nameStartsWith', (value) -> @where 'username', 'like', "#{value}%"
                ]
                group = yield new Group(name: 'users').fetch()
                all = yield group.$users.unscoped().fetch()
                flagged = yield group.$users.fetch()

                flagged.length.should.equal 2
                all.length.should.equal 3
                group.$users.length.should.equal 2

        it "uses default scope with relations", co ->
            class User extends db.Model
                tableName: 'users'
                @schema [
                    StringField 'username'
                    Scope 'default', -> @where flag: true
                ]
            class Group extends db.Model
                tableName: 'groups'
                @schema [
                    BelongsToMany User
                ]
            group = yield new Group(name: 'users').fetch()
            flagged = yield group.$users.fetch()
            flagged.length.should.equal 2

            all = yield group.$users.unscoped().fetch()
            all.length.should.equal 3
