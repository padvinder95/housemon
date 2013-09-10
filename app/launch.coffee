module.exports = (app) ->
  console.log "plugins: #{Object.keys(app.config.plugin)}"
  console.info "starting server on port :#{app.config.port}"
