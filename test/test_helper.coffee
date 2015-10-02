chai = require("chai")
chai.should()
global.expect = chai.expect
global.assert = chai.assert
global.xsetTimeout = (t, f) -> setTimeout f, t
global.co = require 'co'
