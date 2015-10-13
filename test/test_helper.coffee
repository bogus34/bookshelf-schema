chai = require("chai")
chai.should()
chai.use require 'chai-as-promised'
global.expect = chai.expect
global.assert = chai.assert
global.xsetTimeout = (t, f) -> setTimeout f, t
global.co = require('co').wrap

