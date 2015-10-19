module.exports =
    Fulfilled: (value) -> new Promise (resolve, reject) -> resolve(value)
    Rejected: (e) -> new Promise (resolve, reject) -> reject(e)
