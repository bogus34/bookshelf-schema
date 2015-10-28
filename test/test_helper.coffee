chai = require("chai")
chai.should()
chai.use require 'chai-as-promised'
chai.use require 'chai-spies'
global.expect = chai.expect
global.assert = chai.assert
global.spy = chai.spy
global.co = require('co').wrap
