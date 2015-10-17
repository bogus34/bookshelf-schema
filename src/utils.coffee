module.exports =
    Fulfilled: (value) -> new Promise (resolve, reject) -> resolve(value)
    Rejected: -> new Promise (resolve, reject) -> reject()
