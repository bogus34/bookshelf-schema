{assign, attach, detach} = require './has_many'

module.exports =
    assign: assign
    attach: attach
    _attachOne: (model, relation, obj, options) ->
        obj.set @relatedData.key('foreignKey'), model.id
        obj.set @relatedData.key('morphKey'), @relatedData.key('morphValue')
        obj.save null, options
    detach: detach
    _detachOne: (model, relation, obj, options) ->
        obj.set @relatedData.key('foreignKey'), null
        obj.set @relatedData.key('morphKey'), null
        obj.save null, options
