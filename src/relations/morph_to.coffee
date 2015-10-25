module.exports =
    assign: (model, relation, obj, morphValue, options) ->
        unless typeof morphValue is 'string'
            options = morphValue
            morphValue = obj?.tableName
        foreignKey = @relatedData.key 'foreignKey'
        morphKey = @relatedData.key 'morphKey'

        model.set foreignKey, obj?.id
        model.set morphKey, morphValue
        model.save(null, options)
