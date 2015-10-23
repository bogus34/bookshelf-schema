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
    Inviter = null

    fixtures =
        alice: co ->
            alice = yield new User(username: 'alice').save()
            profile = yield new Profile(greetings: 'Hola!', user_id: alice.id).save()
            [alice, profile]
        aliceAndBob: co ->
            [alice, bob] = yield [
                 new User(username: 'alice').save()
                 new User(username: 'bob').save()
            ]
            inviter = yield new Inviter(greeting: 'Hello Bob!', user_id: alice.id).save()
            yield bob.save(inviter_id: inviter.id)
            [alice, bob, inviter]

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

        afterEach -> init.truncate 'users', 'profiles'

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

    describe 'through', ->
        before -> init.inviters()

        beforeEach ->
            class Inviter extends db.Model
                tableName: 'inviters'

            class User extends db.Model
                tableName: 'users'

                @schema [
                    StringField 'username'
                    HasOne User, name: 'invited', through: Inviter
                ]

            Inviter.schema [
                StringField 'greeting'
            ]

        afterEach -> init.truncate 'users', 'inviters'

        it 'can access related model', co ->
            [alice, bob, inviter] = yield fixtures.aliceAndBob()
            yield alice.load('invited')
            alice.$invited.should.be.an.instanceof User
            alice.$invited.id.should.equal bob.id

    describe 'onDestroy', ->
        beforeEach ->
            class Profile extends db.Model
                tableName: 'profiles'

                @schema [
                    StringField 'greetings'
                    IntField 'user_id'
                ]

            class User extends db.Model
                tableName: 'users'

        afterEach -> init.truncate 'users', 'profiles'

        it 'can cascade-destroy dependent models', co ->
            User.schema [
                HasOne Profile, onDestroy: 'cascade'
            ]

            [alice, profile] = yield fixtures.alice()
            profile2 = yield new Profile(greetings: 'Hi!').save()

            yield alice.destroy().should.be.fulfilled

            [profile, profile2] = yield [
                new Profile(id: profile.id).fetch()
                new Profile(id: profile2.id).fetch()
            ]

            expect(profile).to.be.null
            expect(profile2).not.to.be.null

        it 'can reject destroy when there id dependent model', co ->
            User.schema [
                HasOne Profile, onDestroy: 'reject'
            ]

            [alice, _] = yield fixtures.alice()
            yield alice.destroy().should.be.rejected
            yield alice.$profile.assign null
            alice.destroy()

        it 'can detach dependent models on destroy', co ->
            User.schema [
                HasOne Profile, onDestroy: 'detach'
            ]

            [alice, profile] = yield fixtures.alice()
            yield alice.destroy().should.be.fulfilled

            profile = yield new Profile(id: profile.id).fetch()
            expect(profile.user_id).to.be.null
