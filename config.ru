require './app'

DB = PStore.new('data.pstore')

class DBTransactionMiddleware
  def initialize(app)
    @app = app
    DB.transaction { DB[:times] ||= [] }
  end

  def call(env)
    DB.transaction do
      @app.call(env)
    end
  end
end

$stdout.sync = true

use DBTransactionMiddleware
run App
