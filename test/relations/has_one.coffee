Bookshelf = require 'bookshelf'
Schema = require '../../src/'
init = require '../init'
Fields = require '../../src/fields'
Relations = require '../../src/relations'

{StringField, IntField, EmailField} = Fields
{HasOne} = Relations

describe "Relations", ->
    this.timeout 3000
    db = null
    User = null
    Profile = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            profile = yield new Profile(greetings: 'Hola!', user_id: alice.id).save()
            [alice, profile]

    before co ->
        db = init.init()
        yield [ init.users(), init.profiles() ]

    describe 'HasOne', ->
        beforeEach ->
            class Profile extends db.Model
                tableName: 'profiles'

                @schema [
                    StringField 'greetings'
                    IntField 'user_id'
                ]

            class User extends db.Model
                tableName: 'users'

                @schema [
                    StringField 'username'
                    HasOne Profile
                ]

        afterEach co ->
            yield [ db.knex('users').truncate(), db.knex('profiles').truncate() ]

        it 'creates accessor', co ->
            [alice, _] = yield fixtures.alice()
            alice.profile.should.be.a 'function'
            yield alice.load('profile')
            alice.$profile.should.be.an.instanceof db.Model
            alice.$profile.user_id.should.equal alice.id

        it 'can assign model', co ->
            [alice, profile] = yield fixtures.alice()

            profile2 = yield new Profile(greetings: 'Hi!').save()
            yield alice.$profile.assign profile2
            profile = yield Profile.forge(id: profile.id).fetch()
            alice = yield User.forge(id: alice.id).fetch(withRelated: 'profile')

            expect(profile.user_id).to.be.null
            alice.$profile.id.should.equal profile2.id

        it 'can assign plain object', co ->
            [alice, profile] = yield fixtures.alice()

            yield alice.$profile.assign {greetings: 'Hi!'}
            [alice, profile] = yield [
                User.forge(id: alice.id).fetch(withRelated: 'profile')
                Profile.forge(id: profile.id).fetch()
            ]

            alice.$profile.greetings.should.equal 'Hi!'
            expect(profile.user_id).to.be.null

        it 'can assign by id', co ->
            [alice, profile] = yield fixtures.alice()

            profile2 = yield new Profile(greetings: 'Hi!').save()
            yield alice.$profile.assign profile2.id
            profile = yield Profile.forge(id: profile.id).fetch()
            alice = yield User.forge(id: alice.id).fetch(withRelated: 'profile')

            expect(profile.user_id).to.be.null
            alice.$profile.id.should.equal profile2.id
