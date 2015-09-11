class Commands

  OPT_ENV = ["e", "env", "[]"]
  OPT_CONF = ["c", "context", "[]"]

  @start: {
    name: "Start"
    options: [
      OPT_ENV
      OPT_CONF
    ]
  }

  @watch: {
    name: "Watch"
    options: do =>
      @start.options
  }

  @run: {
    name: "Run"
    options: [
      OPT_ENV
      OPT_CONF
      ["s", "script", "<>"]
    ]
  }

module.exports = Commands